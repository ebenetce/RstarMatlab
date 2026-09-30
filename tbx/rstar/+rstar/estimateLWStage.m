function stage = estimateLWStage(data, options, is2023, stageNumber, lambdaG, lambdaZ)
%estimateLWStage Estimate one stage of a Laubach-Williams specification.
%
%   The shared rstar.Model workflow invokes this dispatcher once for each
%   stage. The numerical implementations remain local to this file so LW
%   and LW-2023 use exactly the same source code.
%
%   Copyright 2026 The MathWorks, Inc.

arguments
    data table
    options (1,1) rstar.Options
    is2023 (1,1) logical
    stageNumber (1,1) double {mustBeInteger, mustBeBetween(stageNumber, 1, 3)}
    lambdaG (1,1) double {mustBeFinite, mustBeNonnegative} = 0
    lambdaZ (1,1) double {mustBeFinite, mustBeNonnegative} = 0
end

switch stageNumber
    case 1
        stage = estimateStage1(data, options, is2023);
    case 2
        stage = estimateStage2(data, options, is2023, lambdaG);
    case 3
        stage = estimateStage3(data, options, is2023, lambdaG, lambdaZ);
end
end

function out = estimateStage1(data, options, is2023)
[y, piData, oil, imports, rate, dummy] = inputs(data, is2023);
T = numel(y) - 8;
gap = initialGap(y);
[is, isResidual] = initialIS(gap, rate, dummy, is2023, false);
phX = [piData(8:end-1), mean([piData(7:end-2), piData(6:end-3), ...
    piData(5:end-4)], 2), mean([piData(4:end-5), piData(3:end-6), ...
    piData(2:end-7), piData(1:end-8)], 2), gap(4:end-1) - is(end)*dummy(8:end-1), ...
    oil(8:end-1), imports(9:end)];
[ph, ~, sPh] = rstar.utils.ols(phX, piData(9:end));
sIs = sqrt(sum(isResidual.^2) / (T - numel(is)));
Y = [100*y(9:end), piData(9:end)];
X = [100*y(8:end-1), 100*y(7:end-2), piData(8:end-1), ...
    mean([piData(7:end-2),piData(6:end-3),piData(5:end-4)],2), ...
    mean([piData(4:end-5),piData(3:end-6),piData(2:end-7),piData(1:end-8)],2), ...
    oil(8:end-1), imports(9:end)];
if is2023
    X = [X, dummy(9:end), dummy(8:end-1), dummy(7:end-2)];
    theta0 = [is(1:2)', ph(1:2)', ph(4:6)', .85, sIs, sPh, .5, is(end)];
    phiIndex = 12;
else
    theta0 = [is', ph(1:2)', ph(4:6)', .85, sIs, sPh, .5];
    phiIndex = [];
end
[theta0, lb, ub, schedule] = bounds(theta0, options, is2023, 1, T, phiIndex);
xi0 = 100 * hpfilter(y(5:end), Smoothing=36000);
xi0 = xi0(4:-1:2);
[theta, logL, filtered, smoothed, cov0, optimization] = fit(Y, theta0, lb, ub, .2*eye(3), ...
    @(p,c) stage1Map(p,Y,X,xi0,c,schedule,is2023), optimizationOptions(options));
out = struct("theta",theta(:),"logLikelihood",logL,"filteredStates",filtered, ...
    "smoothedStates",smoothed,"potentialFiltered",filtered(:,1)/100, ...
    "potentialSmoothed",smoothed(:,1)/100,"outputGapFiltered", ...
    Y(:,1)-filtered(:,1)-phi(theta,phiIndex)*dummy(9:end), "outputGapSmoothed", ...
    Y(:,1)-smoothed(:,1)-phi(theta,phiIndex)*dummy(9:end), ...
    "initialState",xi0,"initialCovariance",cov0,"kappaSchedule",schedule, ...
    "optimization",optimization);
end

function out = estimateStage2(data, options, is2023, lambdaG)
[y, piData, oil, imports, rate, dummy] = inputs(data, is2023);
T = numel(y) - 8;
gap = initialGap(y);
[is, isResidual] = initialIS(gap, rate, dummy, is2023, true);
phX = [ ...
    piData(8:end-1), ...
    mean([piData(7:end-2), piData(6:end-3), piData(5:end-4)], 2), ...
    mean([piData(4:end-5), piData(3:end-6), piData(2:end-7), piData(1:end-8)], 2), ...
    gap(4:end-1) - is(end) * dummy(8:end-1), ...
    oil(8:end-1), ...
    imports(9:end)];
[ph, ~, sPh] = rstar.utils.ols(phX, piData(9:end));
sIs = sqrt(sum(isResidual.^2) / (T - numel(is)));
Y = [100 * y(9:end), piData(9:end)];
X = [ ...
    100 * y(8:end-1), ...
    100 * y(7:end-2), ...
    rate(8:end-1), ...
    rate(7:end-2), ...
    piData(8:end-1), ...
    mean([piData(7:end-2), piData(6:end-3), piData(5:end-4)], 2), ...
    mean([piData(4:end-5), piData(3:end-6), piData(2:end-7), piData(1:end-8)], 2), ...
    oil(8:end-1), ...
    imports(9:end), ...
    ones(T,1)];
if is2023
    X = [X, dummy(9:end), dummy(8:end-1), dummy(7:end-2)];
    theta0 = [is(1:4)', -is(3), ph(1:2)', ph(4:6)', sIs, sPh, 0.5, is(end)];
    phiIndex = 14;
else
    theta0 = [is', -is(3), ph(1:2)', ph(4:6)', sIs, sPh, 0.5];
    phiIndex = [];
end
[theta0, lb, ub, schedule] = bounds(theta0, options, is2023, 2, T, phiIndex);
trend = hpfilter(y(5:end), Smoothing=36000);
growth = diff(trend);
if is2023
    xi0 = [100 * trend(4:-1:2); 100 * growth(3:-1:1)];
else
    xi0 = [100 * trend(4:-1:2); 100 * growth(3)];
end
[theta, logL, filtered, smoothed, cov0, optimization] = fit(Y, theta0, lb, ub, .2 * eye(numel(xi0)), ...
    @(p, c) stage2Map(p, Y, X, lambdaG, xi0, c, schedule, is2023), ...
    optimizationOptions(options));
potential = [smoothed(1,[3, 2])'; smoothed(:,1)];
gapSmoothed = 100 * y(7:end) - potential - phi(theta, phiIndex) * dummy(7:end);
out = struct("theta", theta(:), "logLikelihood", logL, ...
    "filteredStates", filtered, "smoothedStates", smoothed, ...
    "trendFiltered", 4 * filtered(:,4), "trendSmoothed", 4 * smoothed(:,4), ...
    "potentialFiltered", filtered(:,1) / 100, "potentialSmoothed", potential, ...
    "outputGapFiltered", Y(:,1) - filtered(:,1) - phi(theta, phiIndex) * dummy(9:end), ...
    "outputGapSmoothed", gapSmoothed, "y", gapSmoothed(3:end), ...
    "x", [gapSmoothed(2:end-1), gapSmoothed(1:end-2), mean(X(:,3:4), 2), ...
    4 * smoothed(:,4), ones(T,1)], "kappa", ...
    rstar.utils.kappaValues(theta, schedule), ...
    "kappaSchedule", schedule, "initialState", xi0, "initialCovariance", cov0, ...
    "optimization", optimization);
end

function results = estimateStage3(data, options, usesCovidAdjustments, lambdaG, lambdaZ)
%estimateStage3 Estimate r-star and its time-varying z component.

[logOutput, inflation, oilInflation, importInflation, realRate, covidDummy] = ...
    inputs(data, usesCovidAdjustments);
numberOfPeriods = numel(logOutput) - 8;
initialOutputGap = initialGap(logOutput);
[isParameters, isResiduals] = initialIS(initialOutputGap, realRate, ...
    covidDummy, usesCovidAdjustments, true);

phillipsRegressors = [inflation(8:end-1), ...
    mean([inflation(7:end-2), inflation(6:end-3), inflation(5:end-4)], 2), ...
    mean([inflation(4:end-5), inflation(3:end-6), inflation(2:end-7), inflation(1:end-8)], 2), ...
    initialOutputGap(4:end-1) - isParameters(end) * covidDummy(8:end-1), ...
    oilInflation(8:end-1), importInflation(9:end)];
[phillipsParameters, ~, phillipsStandardDeviation] = ...
    rstar.utils.ols(phillipsRegressors, inflation(9:end));
isStandardDeviation = sqrt(sum(isResiduals.^2) / (numberOfPeriods - numel(isParameters)));

observations = [100 * logOutput(9:end), inflation(9:end)];
regressors = stage3Regressors(logOutput, inflation, realRate, oilInflation, ...
    importInflation, covidDummy, usesCovidAdjustments);
[initialParameters, phiIndex] = stage3InitialParameters(isParameters, ...
    phillipsParameters, isStandardDeviation, phillipsStandardDeviation, usesCovidAdjustments);
[initialParameters, lowerBounds, upperBounds, kappaSchedule] = ...
    bounds(initialParameters, options, usesCovidAdjustments, 3, numberOfPeriods, phiIndex);
initialState = stage3InitialState(logOutput, usesCovidAdjustments);

[parameters, logLikelihood, filteredStates, smoothedStates, initialCovariance, optimization] = ...
    fit(observations, initialParameters, lowerBounds, upperBounds, ...
    .2 * eye(numel(initialState)), @(parameter, covariance) stage3Map( ...
    parameter, observations, regressors, lambdaG, lambdaZ, initialState, ...
    covariance, kappaSchedule, usesCovidAdjustments), optimizationOptions(options));

zStateIndex = 6 + usesCovidAdjustments;
trendFiltered = 4 * filteredStates(:,4);
trendSmoothed = 4 * smoothedStates(:,4);
covidPhi = phi(parameters, phiIndex);
results = struct("theta", parameters(:), "logLikelihood", logLikelihood, ...
    "filteredStates", filteredStates, "smoothedStates", smoothedStates, ...
    "trendFiltered", trendFiltered, "trendSmoothed", trendSmoothed, ...
    "zFiltered", filteredStates(:,zStateIndex), "zSmoothed", smoothedStates(:,zStateIndex), ...
    "rstarFiltered", parameters(9) * trendFiltered + filteredStates(:,zStateIndex), ...
    "rstarSmoothed", parameters(9) * trendSmoothed + smoothedStates(:,zStateIndex), ...
    "potentialFiltered", filteredStates(:,1) / 100, "potentialSmoothed", smoothedStates(:,1) / 100, ...
    "outputGapFiltered", observations(:,1) - filteredStates(:,1) - covidPhi * covidDummy(9:end), ...
    "outputGapSmoothed", observations(:,1) - smoothedStates(:,1) - covidPhi * covidDummy(9:end), ...
    "kappaSchedule", kappaSchedule, "initialState", initialState, ...
    "initialCovariance", initialCovariance, "optimization", optimization);
end

function regressors = stage3Regressors( ...
        logOutput, inflation, realRate, oilInflation, importInflation, ...
        covidDummy, usesCovidAdjustments)
%stage3Regressors Assemble the observation-equation regressors for stage 3.

inflationAverage = mean([inflation(7:end-2), inflation(6:end-3), inflation(5:end-4)], 2);
inflationLagAverage = mean([inflation(4:end-5), inflation(3:end-6), ...
    inflation(2:end-7), inflation(1:end-8)], 2);
regressors = [100 * logOutput(8:end-1), 100 * logOutput(7:end-2), ...
    realRate(8:end-1), realRate(7:end-2), inflation(8:end-1), ...
    inflationAverage, inflationLagAverage, oilInflation(8:end-1), ...
    importInflation(9:end)];
if usesCovidAdjustments
    regressors = [regressors, covidDummy(9:end), covidDummy(8:end-1), ...
        covidDummy(7:end-2)];
end
end

function [parameters, phiIndex] = stage3InitialParameters(isParameters, phillipsParameters, ...
        isStandardDeviation, phillipsStandardDeviation, usesCovidAdjustments)
%stage3InitialParameters Return the published stage-3 parameter ordering.

parameters = [isParameters(1:3)', phillipsParameters(1:2)', ...
    phillipsParameters(4:6)', 1, isStandardDeviation, ...
    phillipsStandardDeviation, .7];
phiIndex = [];
if usesCovidAdjustments
    parameters = [parameters, isParameters(end)];
    phiIndex = 13;
end
end

function initialState = stage3InitialState(logOutput, usesCovidAdjustments)
%stage3InitialState Initialize potential output, growth, and z states.

trend = hpfilter(logOutput(5:end), Smoothing=36000);
growth = diff(trend);
if usesCovidAdjustments
    initialState = [100 * trend(4:-1:2); 100 * growth(3:-1:1); zeros(3,1)];
else
    initialState = [100 * trend(4:-1:2); 100 * growth(3); ...
        100 * growth(3); 0; 0];
end
end

function [theta, logL, filtered, smoothed, cov0, optimization] = fit( ...
        Y, theta0, lb, ub, cov0, map, opts)
[theta, logL, filtered, smoothed, cov0, optimization] = rstar.utils.fitStateSpace( ...
    Y, theta0, lb, ub, cov0, map, OptimizationOptions=opts);
end

function opts = optimizationOptions(options)
opts = options.OptimizationOptions;
end

function [theta, lb, ub, schedule] = bounds(theta, options, is2023, stage, T, phiIndex)
lb = -inf(size(theta));
ub = inf(size(theta));
if stage == 1
    phillipsSlopeIndex = 5;
    scaleIndices = 9:11;
else
    phillipsSlopeIndex = 8 - 2 * (stage == 3);
    scaleIndices = (numel(theta) - 2 - is2023):numel(theta) - is2023;
end
lb(phillipsSlopeIndex) = options.PhillipsCurveLowerBound;
theta(phillipsSlopeIndex) = max(theta(phillipsSlopeIndex), ...
    lb(phillipsSlopeIndex));
if stage > 1
    ub(3) = options.ISCurveUpperBound;
    theta(3) = min(theta(3), ub(3));
end
lb(scaleIndices) = 0;
schedule = zeros(T,1);
if ~is2023
    return
end
if ~options.EstimatePhi
    lb(phiIndex) = options.FixedPhi;
    ub(phiIndex) = options.FixedPhi;
    theta(phiIndex) = options.FixedPhi;
end
if ~options.UseKappa
    return
end
[theta, lb, ub, schedule] = rstar.utils.appendKappaParameters(theta, lb, ub, T, ...
    KappaInputs=options.KappaInputs, SampleStart=options.SampleStart, ...
    UseKappa=options.UseKappa);
end

function [A, B, C, D, Mean0, Cov0, StateType, DeflateY] = ...
        stage1Map(parameters, observations, regressors, initialState, ...
        initialCovariance, kappaSchedule, usesCovidAdjustments)
%stage1Map Map stage-1 parameters to the LW state-space representation.
%
% States are [y*_t, y*_(t-1), y*_(t-2)].  The first observation is
% log output and the second is inflation.

outputLag1 = parameters(1);
outputLag2 = parameters(2);
phillipsSlope = parameters(5);
outputGapStd = parameters(9);
inflationStd = parameters(10);
potentialOutputStd = parameters(11);

A = [1, 0, 0; 1, 0, 0; 0, 1, 0];
B = diag([potentialOutputStd, 0, 0]);
C = [1, -outputLag1, -outputLag2; 0, -phillipsSlope, 0];
D = rstar.utils.observationNoise(parameters, outputGapStd, inflationStd, ...
    kappaSchedule);

regressionCoefficients = [ ...
    outputLag1, phillipsSlope
    outputLag2, 0
    0, parameters(3)
    0, parameters(4)
    0, 1 - parameters(3) - parameters(4)
    0, parameters(6)
    0, parameters(7)];
if usesCovidAdjustments
    phi = parameters(12);
    regressionCoefficients = [regressionCoefficients
        phi, 0
        -outputLag1 * phi, -phillipsSlope * phi
        -outputLag2 * phi, 0];
end

timeIndex = (1:size(observations,1))';
observations(:,1) = observations(:,1) - timeIndex * parameters(8);
regressors(:,1) = regressors(:,1) - (timeIndex - 1) * parameters(8);
regressors(:,2) = regressors(:,2) - (timeIndex - 2) * parameters(8);

Mean0 = initialState;
Cov0 = initialCovariance;
StateType = [2, 2, 2];
DeflateY = observations - regressors * regressionCoefficients;
end

function [A, B, C, D, Mean0, Cov0, StateType, DeflateY] = ...
        stage2Map(parameters, observations, regressors, lambdaG, initialState, ...
        initialCovariance, kappaSchedule, usesCovidAdjustments)
%stage2Map Map stage-2 parameters to the LW state-space representation.
%
% The 2023 specification retains three lags of trend growth; the original
% specification has one growth state.

outputLag1 = parameters(1);
outputLag2 = parameters(2);
interestRateSlope = parameters(3);
growthSlope = parameters(5);
phillipsSlope = parameters(8);
outputGapStd = parameters(11);
inflationStd = parameters(12);
potentialOutputStd = parameters(13);

if usesCovidAdjustments
    A = [1,0,0,1,0,0; 1,0,0,0,0,0; 0,1,0,0,0,0; ...
         0,0,0,1,0,0; 0,0,0,1,0,0; 0,0,0,0,1,0];
else
    A = [1,0,0,1; 1,0,0,0; 0,1,0,0; 0,0,0,1];
end

B = diag([potentialOutputStd, zeros(1,size(A,1)-1)]);
B(4,4) = lambdaG * potentialOutputStd;
C = [1,-outputLag1,-outputLag2,0,growthSlope/2,growthSlope/2
     0,-phillipsSlope,0,0,0,0];
C = C(:,1:size(A,1));
D = rstar.utils.observationNoise(parameters, outputGapStd, inflationStd, ...
    kappaSchedule);

regressionCoefficients = [ ...
    outputLag1, phillipsSlope
    outputLag2, 0
    interestRateSlope/2, 0
    interestRateSlope/2, 0
    0, parameters(6)
    0, parameters(7)
    0, 1 - parameters(6) - parameters(7)
    0, parameters(9)
    0, parameters(10)
    parameters(4), 0];
if usesCovidAdjustments
    phi = parameters(14);
    regressionCoefficients = [regressionCoefficients
        phi, 0
        -outputLag1 * phi, -phillipsSlope * phi
        -outputLag2 * phi, 0];
end

Mean0 = initialState;
Cov0 = initialCovariance;
StateType = [0, 0, 0, repmat(2,1,size(A,1)-3)];
DeflateY = observations - regressors * regressionCoefficients;
end

function [A, B, C, D, Mean0, Cov0, StateType, DeflateY] = stage3Map( ...
        parameters, observations, regressors, lambdaG, lambdaZ, initialState, ...
        initialCovariance, kappaSchedule, usesCovidAdjustments)
%stage3Map Map stage-3 parameters to the LW state-space representation.

outputLag1 = parameters(1);
outputLag2 = parameters(2);
interestRateSlope = parameters(3);
phillipsSlope = parameters(6);
growthContribution = parameters(9);
outputGapStd = parameters(10);
inflationStd = parameters(11);
potentialOutputStd = parameters(12);

numberOfStates = 7 + 2 * usesCovidAdjustments;
A = zeros(numberOfStates);
A(1, [1, 4]) = 1;
A(2, 1) = 1;
A(3, 2) = 1;
A(4, 4) = 1;
A(5, 4) = 1;
A(6, 6) = 1;
A(7, 6) = 1;
if usesCovidAdjustments
    A = zeros(9);
    A(1, [1, 4]) = 1;
    A(2, 1) = 1;
    A(3, 2) = 1;
    A(4, 4) = 1;
    A(5, 4) = 1;
    A(6, 5) = 1;
    A(7, 7) = 1;
    A(8, 7) = 1;
    A(9, 8) = 1;
end

B = diag([potentialOutputStd, zeros(1, numberOfStates - 1)]);
B(4, 4) = lambdaG * potentialOutputStd;
zStateIndex = 6 + usesCovidAdjustments;
B(zStateIndex, zStateIndex) = lambdaZ * outputGapStd / interestRateSlope;

if usesCovidAdjustments
    C = [1, -outputLag1, -outputLag2, 0, ...
        -2 * growthContribution * interestRateSlope, ...
        -2 * growthContribution * interestRateSlope, 0, ...
        -interestRateSlope / 2, -interestRateSlope / 2
        0, -phillipsSlope, 0, 0, 0, 0, 0, 0, 0];
else
    C = [1, -outputLag1, -outputLag2, ...
        -2 * growthContribution * interestRateSlope, ...
        -2 * growthContribution * interestRateSlope, ...
        -interestRateSlope / 2, -interestRateSlope / 2
        0, -phillipsSlope, 0, 0, 0, 0, 0];
end
D = rstar.utils.observationNoise(parameters, outputGapStd, inflationStd, ...
    kappaSchedule);

regressionCoefficients = [ ...
    outputLag1, phillipsSlope
    outputLag2, 0
    interestRateSlope / 2, 0
    interestRateSlope / 2, 0
    0, parameters(4)
    0, parameters(5)
    0, 1 - parameters(4) - parameters(5)
    0, parameters(7)
    0, parameters(8)];
if usesCovidAdjustments
    covidPhi = parameters(13);
    regressionCoefficients = [regressionCoefficients
        covidPhi, 0
        -outputLag1 * covidPhi, -phillipsSlope * covidPhi
        -outputLag2 * covidPhi, 0];
end

Mean0 = initialState;
Cov0 = initialCovariance;
StateType = [0, 0, 0, 2, 2, 0, 0, zeros(1, 2 * usesCovidAdjustments)];
DeflateY = observations - regressors * regressionCoefficients;
end

function [logOutput, inflation, oilInflation, importInflation, realRate, covidDummy] = ...
        inputs(data, usesCovidAdjustments)
%inputs Extract consistently named input vectors from an LW data table.

logOutput = data.("gdp.log");
inflation = data.inflation;
oilInflation = data.("oil.price.inflation") - inflation;
importInflation = data.("import.price.inflation") - inflation;
realRate = data.interest - data.("inflation.expectations");
covidDummy = zeros(size(logOutput));
if usesCovidAdjustments
    covidDummy = data.("covid.ind");
end
end

function outputGap = initialGap(logOutput)
%initialGap Estimate the LW deterministic trend with two historical breaks.

numberOfObservations = numel(logOutput) - 4;
timeIndex = (1:numberOfObservations)';
design = [ones(numberOfObservations,1), timeIndex, ...
    max(timeIndex - 56, 0), max(timeIndex - 142, 0)];
response = logOutput(5:end);
[coefficients, ~, ~] = rstar.utils.ols(design, response);
outputGap = 100 * (response - design * coefficients);
end

function [parameters, residual] = initialIS(gap, rate, dummy, is2023, includeRate)
response = gap(5:end);
lag1 = gap(4:end-1);
lag2 = gap(3:end-2);
indicator = dummy(9:end);
indicatorLag1 = dummy(8:end-1);
indicatorLag2 = dummy(7:end-2);
if includeRate
    averageRate = mean([rate(8:end-1), rate(7:end-2)], 2);
else
    averageRate = [];
end
if is2023
    if includeRate
        residualFunction = @(v) response - v(5) * indicator - ...
            v(1) * (lag1 - v(5) * indicatorLag1) - ...
            v(2) * (lag2 - v(5) * indicatorLag2) - ...
            v(3) * averageRate - v(4);
        parameters = lsqnonlin(residualFunction, zeros(5,1), [], [], ...
            optimoptions(@lsqnonlin, Display="off"));
    else
        residualFunction = @(v) response - v(3) * indicator - ...
            v(1) * (lag1 - v(3) * indicatorLag1) - ...
            v(2) * (lag2 - v(3) * indicatorLag2);
        parameters = lsqnonlin(residualFunction, zeros(3,1), [], [], ...
            optimoptions(@lsqnonlin, Display="off"));
    end
else
    design = [lag1, lag2];
    if includeRate
        design = [design, averageRate, ones(numel(response),1)];
    end
    parameters = rstar.utils.ols(design, response);
end
if is2023
    phiValue = parameters(end);
else
    phiValue = 0;
end
residual = response - phiValue * indicator - ...
    parameters(1) * (lag1 - phiValue * indicatorLag1) - ...
    parameters(2) * (lag2 - phiValue * indicatorLag2);
if includeRate
    residual = residual - parameters(3) * averageRate - parameters(4);
end
end

function value = phi(theta, index)
value = 0;
if ~isempty(index)
    value=theta(index);
end
end
