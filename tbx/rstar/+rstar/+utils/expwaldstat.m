function [lambda, exponentialWald, lambdaIndex] = expwaldstat(response, predictors, options)
%expwaldstat Estimate a signal-to-noise ratio from an exponential-Wald statistic.
%
%   lambda = rstar.utils.expwaldstat(response, predictors) computes the
%   Stock-Watson (1998) exponential-Wald statistic over all admissible
%   break dates and maps it to its median-unbiased signal-to-noise estimate.
%
%   lambda = rstar.utils.expwaldstat(..., Weights=weights) uses weighted
%   least squares. Scale controls the denominator used to convert the
%   table index to lambda and defaults to the number of observations.
%
%   Copyright 2026 The MathWorks, Inc.

arguments
    response (:,1) double {mustBeFinite, mustBeReal}
    predictors (:,:) double {mustBeFinite, mustBeReal}
    options.Weights (:,1) double {mustBeFinite, mustBeReal, mustBePositive} = ...
        ones(size(response))
    options.Scale (1,1) double {mustBeFinite, mustBeReal, mustBePositive} = ...
        numel(response)
end

numberOfPeriods = numel(response);
if size(predictors, 1) ~= numberOfPeriods || numel(options.Weights) ~= numberOfPeriods
    error("rstar:utils:expwaldstat:DimensionMismatch", ...
        "response, predictors, and Weights must have the same row count.");
end
if numberOfPeriods < 8
    error("rstar:utils:expwaldstat:InsufficientObservations", ...
        "At least eight observations are required for the break-date grid.");
end

statistics = zeros(numberOfPeriods - 7, 1);
for breakIndex = 4:(numberOfPeriods - 4)
    breakRegressor = [zeros(breakIndex, 1); ones(numberOfPeriods - breakIndex, 1)];
    design = [predictors, breakRegressor];
    normalMatrix = design' * (options.Weights .* design);
    coefficients = normalMatrix \ (design' * (options.Weights .* response));
    inverseNormalMatrix = normalMatrix \ eye(size(normalMatrix));
    residuals = response - design * coefficients;
    residualVariance = sum(options.Weights .* residuals.^2) / ...
        (sum(options.Weights) - size(design, 2));
    statistics(breakIndex - 3) = coefficients(end) / ...
        sqrt(residualVariance * inverseNormalMatrix(end,end));
end

exponentialWald = log(mean(exp(statistics.^2 / 2)));
criticalValues = [0.426, 0.476, 0.516, 0.661, 0.826, 1.111, ...
    1.419, 1.762, 2.355, 2.91, 3.413, 3.868, 4.925, 5.684, ...
    6.670, 7.690, 8.477, 9.191, 10.693, 12.024, 13.089, ...
    14.440, 16.191, 17.332, 18.699, 20.464, 21.667, 23.851, ...
    25.538, 26.762, 27.874];

if exponentialWald <= criticalValues(1)
    lambdaIndex = 0;
else
    interval = find(exponentialWald > criticalValues(1:end-1) & ...
        exponentialWald <= criticalValues(2:end), 1);
    if isempty(interval)
        error("rstar:utils:expwaldstat:OutOfRange", ...
            "The exponential-Wald statistic is outside the published table.");
    end
    lambdaIndex = interval - 1 + ...
        (exponentialWald - criticalValues(interval)) / ...
        (criticalValues(interval + 1) - criticalValues(interval));
end

lambda = lambdaIndex / options.Scale;
end
