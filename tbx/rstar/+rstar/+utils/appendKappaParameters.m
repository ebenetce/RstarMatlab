function [parameters, lowerBounds, upperBounds, schedule] = appendKappaParameters( ...
        parameters, lowerBounds, upperBounds, numberOfPeriods, options)
%appendKappaParameters Append kappa parameters and create their period schedule.
%
%   KappaInputs must contain Name, StartDate, EndDate, InitialValue,
%   LowerBound, and UpperBound. StartDate and EndDate identify inclusive
%   calendar-quarter intervals.
%
%   Copyright 2026 The MathWorks, Inc.

arguments
    parameters {mustBeNumeric, mustBeFinite, mustBeReal}
    lowerBounds {mustBeNumeric, mustBeReal}
    upperBounds {mustBeNumeric, mustBeReal}
    numberOfPeriods (1,1) double {mustBeInteger, mustBeReal, mustBePositive}
    options.KappaInputs table
    options.SampleStart (1,1) datetime
    options.UseKappa (1,1) logical
end

schedule = zeros(numberOfPeriods, 1);
if ~options.UseKappa
    return
end

requiredVariables = ["Name", "StartDate", "EndDate", "InitialValue", ...
    "LowerBound", "UpperBound"];
variableNames = string(options.KappaInputs.Properties.VariableNames);
missingVariables = setdiff(requiredVariables, variableNames);
if ~isempty(missingVariables)
    error("rstar:utils:appendKappaParameters:MissingKappaInputs", ...
        "KappaInputs must contain: %s.", strjoin(requiredVariables, ", "));
end
if ~isdatetime(options.KappaInputs.StartDate) || ...
        ~isdatetime(options.KappaInputs.EndDate) || ...
        any(ismissing(options.KappaInputs.StartDate)) || ...
        any(ismissing(options.KappaInputs.EndDate)) || ...
        any(options.KappaInputs.EndDate < options.KappaInputs.StartDate)
    error("rstar:utils:appendKappaParameters:InvalidKappaDates", ...
        "Kappa start and end dates must be nonmissing and ordered.");
end

for index = 1:height(options.KappaInputs)
    kappa = options.KappaInputs(index,:);
    startIndex = quarterIndex(kappa.StartDate, options.SampleStart);
    endIndex = quarterIndex(kappa.EndDate, options.SampleStart);
    activeIndex = max(startIndex, 1):min(endIndex, numberOfPeriods);
    parameterIndex = numel(parameters) + 1;
    parameters(parameterIndex) = kappa.InitialValue;
    lowerBounds(parameterIndex) = kappa.LowerBound;
    upperBounds(parameterIndex) = kappa.UpperBound;
    schedule(activeIndex) = parameterIndex;
end
end

function index = quarterIndex(date, sampleStart)
index = (year(date) - year(sampleStart)) * 4 + ...
    quarter(date) - quarter(sampleStart) + 1;
end
