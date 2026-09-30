function [parameters, logLikelihood, filteredStates, smoothedStates, initialCovariance, ...
        optimization] = ...
        fitStateSpace(observations, initialParameters, lowerBounds, upperBounds, ...
        initialCovariance, parameterMap, options)
%fitStateSpace - Fit, filter, and smooth a two-pass state-space model
%   [PARAMETERS,LOGLIKELIHOOD,FILTEREDSTATES,SMOOTHEDSTATES,INITIALCOVARIANCE,
%   OPTIMIZATION] = fitStateSpace(...) also returns the optimizer summaries
%   from the preliminary covariance-initialization fit and final fit.
%
%   Copyright 2026 The MathWorks, Inc.

arguments
    observations (:,:) double {mustBeFinite, mustBeReal}
    initialParameters {mustBeNumeric, mustBeFinite, mustBeReal}
    lowerBounds {mustBeNumeric, mustBeReal}
    upperBounds {mustBeNumeric, mustBeReal}
    initialCovariance (:,:) double {mustBeFinite, mustBeReal}
    parameterMap (1,1) function_handle
    options.OptimizationOptions = rstar.utils.maximumLikelihoodOptions()
end

model = ssm(@(candidate) parameterMap(candidate, initialCovariance));
[preliminaryModel, ~, ~, ~, preliminaryOutput] = estimate( ...
    model, observations, initialParameters, ...
    Options=options.OptimizationOptions, lb=lowerBounds, ub=upperBounds, ...
    Display="off");
[~, ~, filterOutput] = filter(preliminaryModel, observations(1,:));
initialCovariance = filterOutput.ForecastedStatesCov;

model = ssm(@(candidate) parameterMap(candidate, initialCovariance));
[~, parameters, ~, logLikelihood, finalOutput] = estimate(model, observations, ...
    initialParameters, Options=options.OptimizationOptions, ...
    lb=lowerBounds, ub=upperBounds, Display="off");
filteredStates = filter(model, observations, Params=parameters);
smoothedStates = smooth(model, observations, Params=parameters);
optimization = struct("preliminary", preliminaryOutput, "final", finalOutput);
end
