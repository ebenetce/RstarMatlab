classdef HLW2023Model < rstar.Model
    %HLW2023Model Published COVID-adjusted HLW-2023 model.
    %
    %   Copyright 2026 The MathWorks, Inc.

    properties (Constant, Access=private)
        RequiredPresampleQuarters = 4
    end

    methods

        function obj = HLW2023Model(options)
            %HLW2023Model Construct the HLW-2023 estimator.

            arguments
                options (1,1) rstar.HLW2023Config
            end

            obj@rstar.Model(options);
            obj.Name = "HLW2023";
        end

    end

    methods (Access = protected)

        function validateData(~, data)
            requiredVariables = ["gdp.log", "inflation", ...
                "inflation.expectations", "interest", "covid.ind"];
            missingVariables = setdiff(requiredVariables, ...
                string(data.Properties.VariableNames));
            if ~isempty(missingVariables)
                error("rstar:HLW2023Model:MissingVariables", ...
                    "Input data must contain: %s.", ...
                    strjoin(requiredVariables, ", "));
            end
        end

        function data = prepareData(obj, data)
            [data, obj.Options] = rstar.utils.prepareQuarterlyData(data, obj.Options, ...
                obj.RequiredPresampleQuarters);
        end

        function stage = estimateStage1(obj, data)
            stage = estimateStage1HLW2023(data, obj.Options);
        end

        function stage = estimateStage2(obj, data, lambdaG)
            stage = estimateStage2HLW2023(data, obj.Options, lambdaG);
        end

        function stage = estimateStage3(obj, data, lambdaG, lambdaZ)
            stage = estimateStage3HLW2023(data, obj.Options, lambdaG, lambdaZ);
        end
    end
end

% HLW-2023-only numerical implementation
function results = estimateStage1HLW2023(data, config)
%estimateStage1HLW2023 Estimate stage 1 of the COVID-adjusted HLW-2023 model.
%
%   results = rstar.estimateStage1HLW2023(data, config) estimates the potential-output
%   model using an Econometrics Toolbox time-varying linear Gaussian state-space
%   model. data must contain gdp.log, inflation, and covid.ind.

arguments
    data table
    config (1,1) rstar.HLW2023Config = rstar.HLW2023Config
end

requiredVariables = ["gdp.log", "inflation", "covid.ind"];
missingVariables = setdiff(requiredVariables, string(data.Properties.VariableNames));
if ~isempty(missingVariables)
    error("rstar:estimateStage1HLW2023:MissingVariables", ...
        "Input data must contain: %s.", strjoin(requiredVariables, ", "));
end

logOutput = data.("gdp.log");
inflation = data.inflation;
covidIndicator = data.("covid.ind");
numberOfPeriods = numel(logOutput) - 4;

outputGap = initialLinearOutputGap(logOutput);
[isParameters, isResiduals] = stage1InitialISParameters(outputGap, covidIndicator, config);
isStandardDeviation = sqrt(sum(isResiduals.^2) / ...
    (numel(isResiduals) - numel(isParameters)));

phillipsRegressors = [inflation(4:end-1), ...
    mean([inflation(3:end-2), inflation(2:end-3), inflation(1:end-4)], 2), ...
    outputGap(4:end-1) - isParameters(5) * covidIndicator(4:end-1)];
[phillipsParameters, ~, phillipsStandardDeviation] = ...
    rstar.utils.ols(phillipsRegressors, inflation(5:end));

initialState = stage1InitialPotentialState(logOutput, data, config);
observations = [100 * logOutput(5:end), inflation(5:end)];
regressors = [100 * logOutput(4:end-1), 100 * logOutput(3:end-2), ...
    inflation(4:end-1), ...
    mean([inflation(3:end-2), inflation(2:end-3), inflation(1:end-4)], 2), ...
    covidIndicator(5:end), covidIndicator(4:end-1), covidIndicator(3:end-2)];

initialParameters = [isParameters(1:2)', phillipsParameters(1), ...
    phillipsParameters(3), 0.85, isStandardDeviation, ...
    phillipsStandardDeviation, 0.5, isParameters(5)];
lowerBounds = -inf(size(initialParameters));
upperBounds = inf(size(initialParameters));
lowerBounds(4) = config.PhillipsCurveLowerBound;
initialParameters(4) = max(initialParameters(4), lowerBounds(4));

if ~config.EstimatePhi
    lowerBounds(9) = config.FixedPhi;
    upperBounds(9) = config.FixedPhi;
    initialParameters(9) = config.FixedPhi;
end

[initialParameters, lowerBounds, upperBounds, kappaSchedule] = ...
    rstar.utils.appendKappaParameters(initialParameters, lowerBounds, ...
    upperBounds, numberOfPeriods, KappaInputs=config.KappaInputs, ...
    SampleStart=config.SampleStart, UseKappa=config.UseKappa);

options = config.OptimizationOptions;
covariance0 = 0.2 * eye(3);
[parameters, logLikelihood, filteredStates, smoothedStates, covariance0, optimization] = ...
    rstar.utils.fitStateSpace(observations, initialParameters, lowerBounds, ...
    upperBounds, covariance0, @(candidate, covariance) stage1ParameterMap( ...
    candidate, observations, regressors, initialState, covariance, ...
    kappaSchedule), OptimizationOptions=options);

trendAdjustment = [(1:numberOfPeriods)', (0:numberOfPeriods-1)', ...
    (-1:numberOfPeriods-2)'] * parameters(5);
filteredStates = filteredStates + trendAdjustment;
smoothedStates = smoothedStates + trendAdjustment;

results.theta = parameters(:);
results.logLikelihood = logLikelihood;
results.filteredStates = filteredStates;
results.smoothedStates = smoothedStates;
results.potentialFiltered = filteredStates(:,1) / 100;
results.potentialSmoothed = smoothedStates(:,1) / 100;
results.outputGapFiltered = observations(:,1) - filteredStates(:,1) - ...
    parameters(9) * covidIndicator(5:end);
results.outputGapSmoothed = observations(:,1) - smoothedStates(:,1) - ...
    parameters(9) * covidIndicator(5:end);
results.initialState = initialState;
results.initialCovariance = covariance0;
results.kappaSchedule = kappaSchedule;
results.optimization = optimization;

end

function [parameters, residuals] = stage1InitialISParameters(outputGap, covidIndicator, config)
response = outputGap(5:end);
lag1 = outputGap(4:end-1);
lag2 = outputGap(3:end-2);
indicator = covidIndicator(5:end);
indicatorLag1 = covidIndicator(4:end-1);
indicatorLag2 = covidIndicator(3:end-2);

residuals = @(parameter) response - parameter(3) * indicator - ...
    parameter(1) * (lag1 - parameter(3) * indicatorLag1) - ...
    parameter(2) * (lag2 - parameter(3) * indicatorLag2);
estimatedParameters = lsqnonlin(residuals, zeros(3,1), [], [], ...
    optimoptions(@lsqnonlin, Display="off"));
parameters = zeros(5,1);
parameters([1, 2, 5]) = estimatedParameters;
if ~config.EstimatePhi
    parameters(5) = config.FixedPhi;
    regressors = [lag1, lag2];
    parameters(1:2) = rstar.utils.ols(regressors, response);
end
residuals = response - parameters(5) * indicator - ...
    parameters(1) * (lag1 - parameters(5) * indicatorLag1) - ...
    parameters(2) * (lag2 - parameters(5) * indicatorLag2);
end

function initialState = stage1InitialPotentialState(logOutput, data, config)
trend = hpfilter(logOutput, Smoothing=36000);
if ismember("date", string(data.Properties.VariableNames))
    startDate = config.SampleStart - calquarters(3);
    startIndex = find(data.date == startDate, 1);
else
    startIndex = 2;
end
if isempty(startIndex)
    error("rstar:estimateStage1HLW2023:MissingPresample", ...
        "data must include the quarter three periods before SampleStart.");
end
potentialGrowth = trend(startIndex:end);
initialState = 100 * potentialGrowth(3:-1:1);
end

function [A, B, C, D, Mean0, Cov0, StateType, DeflateY] = stage1ParameterMap( ...
    parameters, observations, regressors, initialState, initialCovariance, kappaSchedule)
ay1 = parameters(1);
ay2 = parameters(2);
bpi = parameters(3);
by = parameters(4);
growth = parameters(5);
sigmaGap = parameters(6);
sigmaInflation = parameters(7);
sigmaPotential = parameters(8);
phi = parameters(9);

A = [1, 0, 0; 1, 0, 0; 0, 1, 0];
B = diag([sigmaPotential, 0, 0]);
C = [1, -ay1, -ay2; 0, -by, 0];
D = rstar.utils.observationNoise(parameters, sigmaGap, sigmaInflation, ...
    kappaSchedule);

regressionCoefficients = [ay1, by; ay2, 0; 0, bpi; 0, 1-bpi; ...
    phi, 0; -ay1 * phi, -by * phi; -ay2 * phi, 0];
adjustedObservations = observations;
adjustedRegressors = regressors;
timeIndex = (1:size(observations,1))';
adjustedObservations(:,1) = adjustedObservations(:,1) - timeIndex * growth;
adjustedRegressors(:,1) = adjustedRegressors(:,1) - (timeIndex - 1) * growth;
adjustedRegressors(:,2) = adjustedRegressors(:,2) - (timeIndex - 2) * growth;

Mean0 = initialState;
Cov0 = initialCovariance;
StateType = [2, 2, 2];
DeflateY = adjustedObservations - adjustedRegressors * regressionCoefficients;
end

function results = estimateStage2HLW2023(data, config, lambdaG)
%estimateStage2HLW2023 Estimate stage 2 of the COVID-adjusted HLW-2023 model.

arguments
    data table
    config (1,1) rstar.HLW2023Config
    lambdaG (1,1) double {mustBeFinite, mustBeNonnegative}
end

setup = stage23Setup(data, config);
y = setup.logOutput;
piData = setup.inflation;
d = setup.covidIndicator;
realRate = setup.realRate;
T = setup.numberOfPeriods;
is = setup.isParameters;
sIs = setup.isStandardDeviation;
ph = setup.phillipsParameters;
sPh = setup.phillipsStandardDeviation;
Y = setup.observations;
X = [ ...
    100 * y(4:end-1), ...
    100 * y(3:end-2), ...
    realRate(4:end-1), ...
    realRate(3:end-2), ...
    piData(4:end-1), ...
    mean([piData(3:end-2), piData(2:end-3), piData(1:end-4)], 2), ...
    ones(T,1), ...
    d(5:end), ...
    d(4:end-1), ...
    d(3:end-2)];
xi0 = initialGrowthState(y, data, config, 0);
theta0 = [is(1:4)', -is(3), ph(1), ph(3), sIs, sPh, 0.5, is(5)];
lb = -inf(size(theta0));
ub = inf(size(theta0));
lb(7) = config.PhillipsCurveLowerBound;
ub(3) = config.ISCurveUpperBound;
theta0(7) = max(theta0(7), lb(7));
theta0(3) = min(theta0(3), ub(3));

if ~config.EstimatePhi
    lb(11) = config.FixedPhi;
    ub(11) = config.FixedPhi;
    theta0(11) = config.FixedPhi;
end

[theta0, lb, ub, schedule] = rstar.utils.appendKappaParameters(theta0, lb, ub, ...
    T, KappaInputs=config.KappaInputs, SampleStart=config.SampleStart, ...
    UseKappa=config.UseKappa);
opts = config.OptimizationOptions;
cov0 = .2 * eye(6);
[theta, logL, filtered, smoothed, cov0, optimization] = rstar.utils.fitStateSpace(Y, theta0, ...
    lb, ub, cov0, @(candidate, covariance) stage2Map(candidate, Y, X, ...
    lambdaG, xi0, covariance, schedule), OptimizationOptions=opts);
potential = [smoothed(1,[3, 2])'; smoothed(:,1)];
outputGap = 100 * y(3:end) - potential - theta(11) * d(3:end);

results.theta = theta(:);
results.logLikelihood = logL;
results.filteredStates = filtered;
results.smoothedStates = smoothed;
results.trendFiltered = 4 * filtered(:,4);
results.trendSmoothed = 4 * smoothed(:,4);
results.potentialSmoothed = potential;
results.outputGapSmoothed = outputGap;
results.outputGapFiltered = Y(:,1) - filtered(:,1) - theta(11) * d(5:end);
results.y = outputGap(3:end);
results.x = [ ...
    outputGap(2:end-1), ...
    outputGap(1:end-2), ...
    mean(X(:,3:4), 2), ...
    results.trendSmoothed, ...
    ones(T,1)];
results.kappaSchedule = schedule;
results.stage2InitialState = xi0;
results.initialCovariance = cov0;
results.optimization = optimization;
results.kappa = rstar.utils.kappaValues(theta, schedule);

end

function gap = initialLinearOutputGap(y)
x = [ones(numel(y),1), (1:numel(y))'];
[coefficients, ~, ~] = rstar.utils.ols(x, y);
gap = 100 * (y - x * coefficients);
end

function setup = stage23Setup(data, config)
%stage23Setup Prepare common initialization inputs for stages 2 and 3.

setup.logOutput = data.("gdp.log");
setup.inflation = data.inflation;
setup.covidIndicator = data.("covid.ind");
setup.realRate = data.interest - data.("inflation.expectations");
setup.numberOfPeriods = numel(setup.logOutput) - 4;

outputGap = initialLinearOutputGap(setup.logOutput);
[setup.isParameters, isResiduals] = initialCovidIS(outputGap, setup.realRate, ...
    setup.covidIndicator, config);
setup.isStandardDeviation = sqrt(sum(isResiduals.^2) / ...
    (setup.numberOfPeriods - numel(setup.isParameters)));

phillipsRegressors = [ ...
    setup.inflation(4:end-1), ...
    mean([setup.inflation(3:end-2), setup.inflation(2:end-3), ...
    setup.inflation(1:end-4)], 2), ...
    outputGap(4:end-1) - setup.isParameters(5) * setup.covidIndicator(4:end-1)];
[setup.phillipsParameters, ~, setup.phillipsStandardDeviation] = ...
    rstar.utils.ols(phillipsRegressors, setup.inflation(5:end));
setup.observations = [100 * setup.logOutput(5:end), setup.inflation(5:end)];
end

function [parameters, residuals] = initialCovidIS(gap, realRate, covidIndicator, config)
response = gap(5:end);
lag1 = gap(4:end-1);
lag2 = gap(3:end-2);
averageRate = mean([realRate(4:end-1), realRate(3:end-2)], 2);
indicator = covidIndicator(5:end);
indicatorLag1 = covidIndicator(4:end-1);
indicatorLag2 = covidIndicator(3:end-2);

residualFunction = @(parameter) response - parameter(5) * indicator - ...
    parameter(1) * (lag1 - parameter(5) * indicatorLag1) - ...
    parameter(2) * (lag2 - parameter(5) * indicatorLag2) - ...
    parameter(3) * averageRate - parameter(4);
parameters = lsqnonlin(residualFunction, zeros(5,1), [], [], ...
    optimoptions(@lsqnonlin, Display="off"));
if ~config.EstimatePhi
    parameters(5) = config.FixedPhi;
    design = [lag1, lag2, averageRate, ones(numel(response),1)];
    parameters(1:4) = rstar.utils.ols(design, response);
end
residuals = response - parameters(5) * indicator - ...
    parameters(1) * (lag1 - parameters(5) * indicatorLag1) - ...
    parameters(2) * (lag2 - parameters(5) * indicatorLag2) - ...
    parameters(3) * averageRate - parameters(4);
end

function initialState = initialGrowthState(y, data, config, numberOfAdditionalStates)
trend = hpfilter(y, Smoothing=36000);
start = find(data.date == config.SampleStart - calquarters(3), 1);
if isempty(start)
    error("rstar:HLW2023Model:MissingPresample", ...
        "Required presample is missing.");
end
growth = diff(trend);
initialState = [ ...
    100 * trend(start+2:-1:start); ...
    100 * growth(start+1:-1:start-1)];
if numberOfAdditionalStates > 0
    initialState = [initialState; zeros(numberOfAdditionalStates,1)];
end
end

function [A, B, C, D, Mean0, Cov0, StateType, DeflateY] = ...
        stage2Map(parameters, observations, regressors, lambdaG, ...
        initialState, initialCovariance, kappaSchedule)
outputLag1 = parameters(1);
outputLag2 = parameters(2);
interestRateSlope = parameters(3);
intercept = parameters(4);
growthSlope = parameters(5);
inflationLagCoefficient = parameters(6);
phillipsSlope = parameters(7);
outputGapStd = parameters(8);
inflationStd = parameters(9);
potentialOutputStd = parameters(10);
phi = parameters(11);

A = [ ...
    1, 0, 0, 1, 0, 0
    1, 0, 0, 0, 0, 0
    0, 1, 0, 0, 0, 0
    0, 0, 0, 1, 0, 0
    0, 0, 0, 1, 0, 0
    0, 0, 0, 0, 1, 0];
B = diag([potentialOutputStd, 0, 0, lambdaG * potentialOutputStd, 0, 0]);
C = [1, -outputLag1, -outputLag2, 0, growthSlope / 2, growthSlope / 2
     0, -phillipsSlope, 0, 0, 0, 0];
D = rstar.utils.observationNoise(parameters, outputGapStd, inflationStd, ...
    kappaSchedule);
regressionCoefficients = [ ...
    outputLag1, phillipsSlope
    outputLag2, 0
    interestRateSlope / 2, 0
    interestRateSlope / 2, 0
    0, inflationLagCoefficient
    0, 1 - inflationLagCoefficient
    intercept, 0
    phi, 0
    -outputLag1 * phi, -phillipsSlope * phi
    -outputLag2 * phi, 0];

Mean0 = initialState;
Cov0 = initialCovariance;
StateType = [0, 0, 0, 2, 2, 2];
DeflateY = observations - regressors * regressionCoefficients;
end

function results = estimateStage3HLW2023(data, config, lambdaG, lambdaZ)
%estimateStage3HLW2023 Estimate stage 3 of the COVID-adjusted HLW-2023 model.

arguments
    data table
    config (1,1) rstar.HLW2023Config
    lambdaG (1,1) double {mustBeFinite, mustBeNonnegative}
    lambdaZ (1,1) double {mustBeFinite, mustBeNonnegative}
end
setup = stage23Setup(data, config);
y = setup.logOutput;
piData = setup.inflation;
d = setup.covidIndicator;
realRate = setup.realRate;
T = setup.numberOfPeriods;
is = setup.isParameters;
sIs = setup.isStandardDeviation;
ph = setup.phillipsParameters;
sPh = setup.phillipsStandardDeviation;
Y = setup.observations;
X = [ ...
    100 * y(4:end-1), ...
    100 * y(3:end-2), ...
    realRate(4:end-1), ...
    realRate(3:end-2), ...
    piData(4:end-1), ...
    mean([piData(3:end-2), piData(2:end-3), piData(1:end-4)], 2), ...
    d(5:end), ...
    d(4:end-1), ...
    d(3:end-2)];
xi0 = initialGrowthState(y, data, config, 3);
theta0 = [is(1:3)', ph(1), ph(3), sIs, sPh, 0.7, is(5), 1];
lb = -inf(size(theta0));
ub = inf(size(theta0));
lb(5) = config.PhillipsCurveLowerBound;
ub(3) = config.ISCurveUpperBound;
theta0(5) = max(theta0(5), lb(5));
theta0(3) = min(theta0(3), ub(3));
if ~config.EstimatePhi
    lb(9) = config.FixedPhi;
    ub(9) = config.FixedPhi;
    theta0(9) = config.FixedPhi;
end
[theta0, lb, ub, schedule] = rstar.utils.appendKappaParameters(theta0, lb, ub, ...
    T, KappaInputs=config.KappaInputs, SampleStart=config.SampleStart, ...
    UseKappa=config.UseKappa);
opts = config.OptimizationOptions;
cov0 = .2 * eye(9);
[theta, logL, filtered, smoothed, cov0, optimization] = rstar.utils.fitStateSpace(Y, theta0, ...
    lb, ub, cov0, @(candidate, covariance) stage3Map(candidate, Y, X, ...
    lambdaG, lambdaZ, xi0, covariance, schedule), OptimizationOptions=opts);
trendFiltered = 4 * filtered(:,4);
trendSmoothed = 4 * smoothed(:,4);
zFiltered = filtered(:,7);
zSmoothed = smoothed(:,7);

results.theta = theta(:);
results.logLikelihood = logL;
results.filteredStates = filtered;
results.smoothedStates = smoothed;
results.trendFiltered = trendFiltered;
results.trendSmoothed = trendSmoothed;
results.zFiltered = zFiltered;
results.zSmoothed = zSmoothed;
results.rstarFiltered = theta(10) * trendFiltered + zFiltered;
results.rstarSmoothed = theta(10) * trendSmoothed + zSmoothed;
results.potentialFiltered = filtered(:,1) / 100;
results.potentialSmoothed = smoothed(:,1) / 100;
results.outputGapFiltered = Y(:,1) - filtered(:,1) - theta(9) * d(5:end);
results.outputGapSmoothed = Y(:,1) - smoothed(:,1) - theta(9) * d(5:end);
results.kappaSchedule = schedule;
results.stage3InitialState = xi0;
results.initialCovariance = cov0;
results.optimization = optimization;
end

function [A, B, C, D, Mean0, Cov0, StateType, DeflateY] = ...
        stage3Map(parameters, observations, regressors, lambdaG, lambdaZ, ...
        initialState, initialCovariance, kappaSchedule)
outputLag1 = parameters(1);
outputLag2 = parameters(2);
interestRateSlope = parameters(3);
inflationLagCoefficient = parameters(4);
phillipsSlope = parameters(5);
outputGapStd = parameters(6);
inflationStd = parameters(7);
potentialOutputStd = parameters(8);
phi = parameters(9);
growthSlope = parameters(10);

A = [ ...
    1, 0, 0, 1, 0, 0, 0, 0, 0
    1, 0, 0, 0, 0, 0, 0, 0, 0
    0, 1, 0, 0, 0, 0, 0, 0, 0
    0, 0, 0, 1, 0, 0, 0, 0, 0
    0, 0, 0, 1, 0, 0, 0, 0, 0
    0, 0, 0, 0, 1, 0, 0, 0, 0
    0, 0, 0, 0, 0, 0, 1, 0, 0
    0, 0, 0, 0, 0, 0, 1, 0, 0
    0, 0, 0, 0, 0, 0, 0, 1, 0];
B = diag([potentialOutputStd, 0, 0, lambdaG * potentialOutputStd, 0, 0, ...
    lambdaZ * outputGapStd / interestRateSlope, 0, 0]);
C = [ ...
    1, -outputLag1, -outputLag2, 0, -2 * growthSlope * interestRateSlope, ...
    -2 * growthSlope * interestRateSlope, 0, -interestRateSlope / 2, ...
    -interestRateSlope / 2
    0, -phillipsSlope, 0, 0, 0, 0, 0, 0, 0];
D = rstar.utils.observationNoise(parameters, outputGapStd, inflationStd, ...
    kappaSchedule);
regressionCoefficients = [ ...
    outputLag1, phillipsSlope
    outputLag2, 0
    interestRateSlope / 2, 0
    interestRateSlope / 2, 0
    0, inflationLagCoefficient
    0, 1 - inflationLagCoefficient
    phi, 0
    -outputLag1 * phi, -phillipsSlope * phi
    -outputLag2 * phi, 0];

Mean0 = initialState;
Cov0 = initialCovariance;
StateType = [0, 0, 0, 2, 2, 2, 0, 0, 0];
DeflateY = observations - regressors * regressionCoefficients;
end
