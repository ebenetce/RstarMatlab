classdef HLWModel < rstar.Model
    %HLWModel Original Holston-Laubach-Williams specification.
    %
    %   Copyright 2026 The MathWorks, Inc.
    methods
        function obj = HLWModel(options)
            obj@rstar.Model(options);
            obj.Name = "HLW";
        end
    end

    methods (Access = protected)
        function validateData(~, data)
            requiredVariables = ["gdp.log", "inflation", ...
                "inflation.expectations", "interest"];
            missingVariables = setdiff(requiredVariables, ...
                string(data.Properties.VariableNames));
            if ~isempty(missingVariables)
                error("rstar:HLWModel:MissingVariables", ...
                    "Input data must contain: %s.", ...
                    strjoin(requiredVariables, ", "));
            end
        end

        function stage = estimateStage1(obj, data)
            logOutput = data.("gdp.log");
            inflation = data.inflation;

            stage = stage1(logOutput, inflation, obj.Options);
        end

        function stage = estimateStage2(obj, data, lambdaG)
            logOutput = data.("gdp.log");
            inflation = data.inflation;
            realRate = data.interest - data.("inflation.expectations");

            stage = stage2(logOutput, inflation, realRate, lambdaG, obj.Options);
        end

        function stage = estimateStage3(obj, data, lambdaG, lambdaZ)
            logOutput = data.("gdp.log");
            inflation = data.inflation;
            realRate = data.interest - data.("inflation.expectations");

            stage = stage3(logOutput, inflation, realRate, lambdaG, lambdaZ, ...
                obj.Options);
        end
    end
end

% HLW-only numerical implementation
function results = stage1(logOutput, inflation, options)

T = length(logOutput) - 4;

% Calculate the index
g_pot_start_index = 2;

% Original output gap estimate
x_og = [ones(T+4, 1), (1:(T+4))'];
y_og = logOutput;
[beta_og, ~, ~] = rstar.utils.ols(x_og, y_og);
output_gap = (y_og - x_og * beta_og) * 100;

trend = hpfilter(logOutput, "Smoothing", 36000);
g_pot = trend(g_pot_start_index:end);

xi_00 = 100 * g_pot(3:-1:1);

% IS curve
y_is = output_gap(5:(T+4));
x_is = [output_gap(4:(T+3)), output_gap(3:(T+2))];
[b_is, ~, s_is] = rstar.utils.ols(x_is, y_is);

% Phillips curve
y_ph = inflation(5:(T+4));
x_ph = [inflation(4:(T+3)), ...
    (inflation(3:(T+2)) + inflation(2:(T+1)) + inflation(1:T)) / 3, ...
    output_gap(4:(T+3))];
[b_ph, ~, s_ph] = rstar.utils.ols(x_ph, y_ph);

y_data = [100 * logOutput(5:(T+4)), ...
    inflation(5:(T+4))];

% Constructing x.data
x_data = [100 * logOutput(4:(T+3)), ...
    100 * logOutput(3:(T+2)), ...
    inflation(4:(T+3)), ...
    (inflation(3:(T+2)) + inflation(2:(T+1)) + inflation(1:T)) / 3];

theta0 = [b_is', b_ph(1), b_ph(3), 0.85, s_is, s_ph, 0.5];

nparams = length(theta0);

    lb = -inf(1,nparams);
    lb(4) = 0.025;
    lb(6:8) = 0;
    ub = inf(1,nparams);

if theta0(4) < lb(4)
    theta0(4) = lb(4);
end

%% Set the initial covariance matrix (see footnote 6)
Cov0 = 0.2*eye( 3 );
[estParams, logL, FilteredStates, SmoothedStates, Cov0, optimization] = ...
    rstar.utils.fitStateSpace(y_data, theta0, lb, ub, Cov0, ...
    @(parameters, covariance) paramMap(parameters, y_data, x_data, xi_00, ...
    covariance), OptimizationOptions=options.OptimizationOptions);

potential_filtered = FilteredStates(:,1)/100;
output_gap_filtered = y_data(:,1) - potential_filtered*100;
potential_smoothed = SmoothedStates(:,1)/100;
output_gap_smoothed = y_data(:,1) - potential_smoothed*100;

results.theta = estParams;
results.logLikelihood = logL;
results.States = struct('filtered', FilteredStates, 'smoothed', SmoothedStates);
results.xi0 = xi_00;
results.Cov0 = Cov0;
results.potentialFiltered = potential_filtered;
results.outputGapFiltered = output_gap_filtered;
results.potentialSmoothed = potential_smoothed;
results.outputGapSmoothed = output_gap_smoothed;
results.optimization = optimization;

end

function [A, B, C, D, Mean0, Cov0, StateType, DeflateY] = paramMap(theta, Y, Z, xi_00, Cov_00)
% Time-invariant state-space model parameter mapping function example. This
% function maps the vector params to the state-space matrices (A, B, C, and
% D), the initial state value and the initial state variance (Mean0 and
% Cov0), and the type of state (StateType). The state model is AR(1)
% without observation error.

% yt - A'Xt = H'xi_t + eps_t
% xi_t = Fxi_{t-1} + eta_t

ay1 = theta(1);
ay2 = theta(2);
bpi = theta(3);
by = theta(4);
g = theta(5);
sy_tilda = theta(6);
spi = theta(7);
sy_star = theta(8);

A = [1, 0, 0; 1, 0, 0; 0, 1, 0]; % F
B = zeros(3);
B(1,1) = sy_star; % B*B' = Q

C = [1, -ay1, -ay2; 0, -by, 0]; % H'
D = [sy_tilda, 0; 0, spi]; % D*D' = R

Ap = [ay1, by; ay2, 0; 0, bpi; 0, 1-bpi]; %A

Mean0 = xi_00;
Cov0 = Cov_00;

StateType = [2 2 2];

idx = (1:numel(Y(:,1)))';
Y(:,1) = Y(:,1) - idx*g;
Z(:,1) = Z(:,1) - (idx-1)*g;
Z(:,2) = Z(:,2) - (idx-2)*g;

DeflateY = Y - Z*Ap;

end


function results = stage2(logOutput, inflation, real_interest_rate, lambda_g, options)

T = length(logOutput) - 4;

% Calculate the index
g_pot_start_index = 2;

% Original output gap estimate
x_og = [ones(T+4, 1), (1:(T+4))'];
y_og = logOutput;
[beta_og, ~, ~] = rstar.utils.ols(x_og, y_og);
output_gap = (y_og - x_og * beta_og) * 100;

trend = hpfilter(logOutput, "Smoothing", 36000);
g_pot = trend(g_pot_start_index:end);
g_pot_diff = diff(g_pot);
xi_00 = [100 * g_pot(3:-1:1); g_pot_diff(3)*100];

% IS curve
y_is = output_gap(5:(T+4));
x_is = [output_gap(4:(T+3)), output_gap(3:(T+2)),(real_interest_rate(4:(T+3)) + real_interest_rate(3:(T+2))) / 2, ones(T,1)];
[b_is, ~, s_is] = rstar.utils.ols(x_is, y_is);

% Phillips curve
y_ph = inflation(5:(T+4));
x_ph = [inflation(4:(T+3)), ...
    (inflation(3:(T+2)) + inflation(2:(T+1)) + inflation(1:T)) / 3, ...
    output_gap(4:(T+3))];
[b_ph, ~, s_ph] = rstar.utils.ols(x_ph, y_ph);

y_data = [100 * logOutput(5:(T+4)), ...
    inflation(5:(T+4))];

% Constructing x.data
x_data = [100 * logOutput(4:(T+3)), ...
    100 * logOutput(3:(T+2)), ...
    real_interest_rate(4:(T+3)), ...
    real_interest_rate(3:(T+2)), ...
    inflation(4:(T+3)), ...
    (inflation(3:(T+2)) + inflation(2:(T+1)) + inflation(1:T)) / 3, ...
    ones(T,1)];

theta0 = [b_is', -b_is(3), b_ph(1), b_ph(3), s_is, s_ph, 0.5];

    lb = -inf(1,10);
    lb(7) = 0.025;
    lb(8:10) = 0;
ub = inf(1,10);
ub(3) = -0.0025;

if theta0(7) < lb(7)
    theta0(7) = lb(7);
end

if theta0(3) > ub(3)
    theta0(3) = ub(3);
end

%% Set the initial covariance matrix (see footnote 6)
Cov0 = 0.2*eye( 4 );
[estParams, logL, FilteredStates, SmoothedStates, Cov0, optimization] = ...
    rstar.utils.fitStateSpace(y_data, theta0, lb, ub, Cov0, ...
    @(parameters, covariance) stage2ParamMap(parameters, y_data, x_data, ...
    lambda_g, xi_00, covariance), OptimizationOptions=options.OptimizationOptions);

trend_filtered = FilteredStates(:,4)*4;
potential_filtered = FilteredStates(:,1)/100;
output_gap_filtered = y_data(:,1) - potential_filtered*100;

trend_smoothed = SmoothedStates(:,4)*4;
potential_smoothed = [SmoothedStates(1,[3,2])'; SmoothedStates(:,1)];
output_gap_smoothed = 100*logOutput(3:(T+4)) - potential_smoothed;

results.y = output_gap_smoothed(3:end);
results.x = [output_gap_smoothed(2:end-1), output_gap_smoothed(1:end-2), (x_data(:,3)+x_data(:,4))/2, SmoothedStates(:,4), ones(T,1)];
results.theta = estParams;
results.logLikelihood = logL;
results.xi0 = xi_00;
results.Cov0 = Cov0;
results.States = struct('filtered', FilteredStates, 'smoothed', SmoothedStates);
results.trendFiltered = trend_filtered;
results.potentialFiltered = potential_filtered;
results.outputGapFiltered = output_gap_filtered;
results.trendSmoothed = trend_smoothed;
results.potentialSmoothed = potential_smoothed;
results.outputGapSmoothed = output_gap_smoothed;
results.optimization = optimization;
results.kappa = ones(T,1);

end

function [A, B, C, D, Mean0, Cov0, StateType, DeflateY] = stage2ParamMap(theta, Y, Z, lambda_g, xi_00, Cov_00)
% Time-invariant state-space model parameter mapping function example. This
% function maps the vector params to the state-space matrices (A, B, C, and
% D), the initial state value and the initial state variance (Mean0 and
% Cov0), and the type of state (StateType). The state model is AR(1)
% without observation error.
ay1 = theta(1);
ay2 = theta(2);
ar = theta(3);
a0 = theta(4);
ag = theta(5);
bpi = theta(6);
by = theta(7);
sy_tilda = theta(8);
spi = theta(9);
sy_star = theta(10);

A = [1, 0, 0, 1; 1, 0, 0, 0; 0, 1, 0, 0; 0, 0, 0, 1]; % F
B = zeros(4); % Q
B(1,1) = sy_star;
B(4,4) = (lambda_g*sy_star);

C = [1, -ay1, -ay2, ag; 0, -by, 0, 0]; % H'
D = [sy_tilda, 0; 0, spi]; % R

Ap = [ay1, by; ay2, 0; ar/2, 0; ar/2, 0; 0, bpi; 0, 1-bpi; a0, 0]; %A'

Mean0 = xi_00;
Cov0 = Cov_00;
StateType = [0, 0, 0, 2];

DeflateY = Y - Z*Ap;
end


function results = stage3(logOutput, inflation, real_interest_rate, lambda_g, lambda_z, options)

T = length(logOutput) - 4;

% Calculate the index
g_pot_start_index = 2;

% Original output gap estimate
x_og = [ones(T+4, 1), (1:(T+4))'];
y_og = logOutput;
[beta_og, ~, ~] = rstar.utils.ols(x_og, y_og);
output_gap = (y_og - x_og * beta_og) * 100;

trend = hpfilter(logOutput, "Smoothing", 36000);
g_pot = trend(g_pot_start_index:end);
g_pot_diff = diff(g_pot);

xi_00 = [100 * g_pot(3:-1:1); g_pot_diff(2:-1:1)*100; 0; 0];

% IS curve
y_is = output_gap(5:(T+4));
x_is = [output_gap(4:(T+3)), output_gap(3:(T+2)),(real_interest_rate(4:(T+3)) + real_interest_rate(3:(T+2))) / 2, ones(T,1)];
[b_is, ~, s_is] = rstar.utils.ols(x_is, y_is);

% Phillips curve
y_ph = inflation(5:(T+4));
x_ph = [inflation(4:(T+3)), ...
        (inflation(3:(T+2)) + inflation(2:(T+1)) + inflation(1:T)) / 3, ...
        output_gap(4:(T+3))];
[b_ph, ~, s_ph] = rstar.utils.ols(x_ph, y_ph);

y_data = [100 * logOutput(5:(T+4)), ...
          inflation(5:(T+4))];

% Constructing x.data
x_data = [100 * logOutput(4:(T+3)), ...
          100 * logOutput(3:(T+2)), ...
          real_interest_rate(4:(T+3)), ...
          real_interest_rate(3:(T+2)), ...
          inflation(4:(T+3)), ...
          (inflation(3:(T+2)) + inflation(2:(T+1)) + inflation(1:T)) / 3];

theta0 = [b_is(1:3)', b_ph(1), b_ph(3), s_is, s_ph, 0.7];

    lb = -inf(1,8);
    lb(5) = 0.025;
    lb(6:8) = 0;

ub = inf(1,8);
ub(3) = -0.0025;

if theta0(5) < lb(5)
    theta0(5) = lb(5);
end

if theta0(3) > ub(3)
    theta0(3) = ub(3);
end

%% Set the initial covariance matrix (see footnote 6)
Cov0 = 0.2*eye( 7 );
[estParams, logL, FilteredStates, SmoothedStates, Cov0, optimization] = ...
    rstar.utils.fitStateSpace(y_data, theta0, lb, ub, Cov0, ...
    @(parameters, covariance) stage3ParamMap(parameters, lambda_g, lambda_z, ...
    y_data, x_data, xi_00, covariance), ...
    OptimizationOptions=options.OptimizationOptions);

trend_filtered = FilteredStates(:,4)*4;
z_filtered = FilteredStates(:,6);
rstar_filtered = trend_filtered + z_filtered;
potential_filtered = FilteredStates(:,1)/100;
output_gap_filtered = y_data(:,1) - potential_filtered*100;

trend_smoothed = SmoothedStates(:,4)*4;
z_smoothed = SmoothedStates(:,6);
rstar_smoothed = trend_smoothed + z_smoothed;
potential_smoothed = SmoothedStates(:,1)/100;
output_gap_smoothed = y_data(:,1) - potential_smoothed*100;

results.rstarFiltered = rstar_filtered;
results.trendFiltered = trend_filtered;
results.zFiltered = z_filtered;
results.potentialFiltered = potential_filtered;
results.outputGapFiltered = output_gap_filtered;
results.rstarSmoothed = rstar_smoothed;
results.trendSmoothed = trend_smoothed;
results.zSmoothed = z_smoothed;
results.potentialSmoothed = potential_smoothed;
results.outputGapSmoothed = output_gap_smoothed;
results.theta = estParams;
results.logLikelihood = logL;
results.states = struct('filtered', FilteredStates, 'smoothed', SmoothedStates);
results.xi0 = xi_00;
results.Cov0 = Cov0;
results.y_data = y_data;
results.theta0 = theta0;
results.optimization = optimization;

end

function [A, B, C, D, Mean0, Cov0, StateType, DeflateY] = stage3ParamMap(theta, lambda_g, lambda_z, Y, Z, xi_00, Cov_00)
% Time-invariant state-space model parameter mapping function example. This
% function maps the vector params to the state-space matrices (A, B, C, and
% D), the initial state value and the initial state variance (Mean0 and
% Cov0), and the type of state (StateType). The state model is AR(1)
% without observation error.
    ay1 = theta(1);
    ay2 = theta(2);
    ar = theta(3);
    bpi = theta(4);    
    by = theta(5);
    sy_tilda = theta(6);
    spi = theta(7);
    sy_star = theta(8);

    A = [
        1, 0, 0, 1, 0, 0, 0; 
        1, 0, 0, 0, 0, 0, 0;
        0, 1, 0, 0, 0, 0, 0;
        0, 0, 0, 1, 0, 0, 0;
        0, 0, 0, 1, 0, 0, 0;
        0, 0, 0, 0, 0, 1, 0;
        0, 0, 0, 0, 0, 1, 0]; % F

    % B = zeros(7); % Q
    % B(1,1) = sqrt(1+lambda_g^2)*sy_star^2;
    % B(1,4) = (lambda_g*sy_star)^2;
    % B(4,1) = (lambda_g*sy_star)^2;
    % B(4,4) = (lambda_g*sy_star)^2;
    % B(6,6) = (lambda_z*sy_tilda/ar)^2;
    % B = qr(B);

    B = zeros(7); % Q
    B(1,1) = sqrt(1+lambda_g^2)*sy_star;
    B(4,1) = (lambda_g*sy_star)^2/(sqrt(1+lambda_g^2)*sy_star);
    B(4,4) = (lambda_g*sy_star)*sqrt((1+lambda_g^2)*sy_star^2 - (lambda_g*sy_star)^2)/(sqrt(1+lambda_g^2)*sy_star);
    B(6,6) = (lambda_z*sy_tilda/ar);
 
    C = [1, -ay1, -ay2, -ar*2, -ar*2, -ar/2, -ar/2; 0, -by, 0, 0, 0, 0, 0]; % H'
    D = [sy_tilda, 0; 0, spi]; % R

    Ap = [ay1, by; ay2, 0; ar/2, 0; ar/2, 0; 0, bpi; 0, 1-bpi]; %A'

    Mean0 = xi_00;
    Cov0 = Cov_00;
    StateType = [0, 0, 0, 2, 2, 0, 0];
    
    DeflateY = Y - Z*Ap;
end
