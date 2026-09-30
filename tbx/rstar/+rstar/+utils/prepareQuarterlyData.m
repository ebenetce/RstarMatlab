function [data, options] = prepareQuarterlyData(data, options, numberOfPresampleQuarters)
%prepareQuarterlyData Validate and select quarterly data for 2023 models.
%
%   [data, options] = rstar.utils.prepareQuarterlyData(data, options, ...
%   numberOfPresampleQuarters)
%   accepts a table
%   with one datetime variable named date, Date, time, or Time, or a
%   timetable whose row times are the observation dates. It returns the
%   selected sample as a table with the canonical variable name date. If
%   SampleStart or SampleEnd is NaT, the returned options set it to the
%   earliest estimable and final available quarters, respectively.
%
%   Copyright 2026 The MathWorks, Inc.

arguments
    data tabular
    options (1,1) rstar.CovidAdjustedOptions
    numberOfPresampleQuarters (1,1) double {mustBeInteger, mustBeNonnegative}
end

if istimetable(data)
    date = data.Properties.RowTimes;
    data = timetable2table(data, ConvertRowTimes=true);
    data.Properties.VariableNames{1} = 'date';    
else
    variableNames = string(data.Properties.VariableNames);
    dateIndex = find(ismember(lower(variableNames), ["date", "time"]));
    if isempty(dateIndex)
        error("rstar:utils:prepareQuarterlyData:MissingDate", ...
            "Input data must contain one datetime variable named date, Date, time, or Time.");
    end
    if numel(dateIndex) > 1
        error("rstar:utils:prepareQuarterlyData:AmbiguousDate", ...
            "Input data must contain only one case-insensitive date or time variable.");
    end
    dateName = variableNames(dateIndex);
    date = data.(dateName);
    if ~isdatetime(date)
        error("rstar:utils:prepareQuarterlyData:InvalidDateType", ...
            "The date or time variable must have datetime values.");
    end
    if dateName ~= "date"
        data = renamevars(data, dateName, "date");
    end
end

if any(ismissing(date))
    error("rstar:utils:prepareQuarterlyData:MissingDateValue", ...
        "The date variable must not contain missing values.");
end
if ~issorted(date)
    error("rstar:utils:prepareQuarterlyData:UnsortedDates", ...
        "The date variable must be sorted in ascending order.");
end
if ~isregular(date, "Quarters")
    error("rstar:utils:prepareQuarterlyData:IrregularDates", ...
        "The date variable must have one observation per quarter.");
end

sampleStart = options.SampleStart;
if isnat(sampleStart)
    sampleStart = data.date(1) + calquarters(numberOfPresampleQuarters);
    options.SampleStart = sampleStart;
end
if isnat(options.SampleEnd)
    options.SampleEnd = data.date(end);
end

firstDate = sampleStart - calquarters(numberOfPresampleQuarters);
keep = data.date >= firstDate;
keep = keep & data.date <= options.SampleEnd;
data = data(keep,:);

minimumObservations = numberOfPresampleQuarters + 9;
sampleStartIndex = numberOfPresampleQuarters + 1;
if height(data) < minimumObservations || data.date(sampleStartIndex) ~= sampleStart
    error("rstar:utils:prepareQuarterlyData:MissingPresample", ...
        "Data must include the required quarterly presample before SampleStart.");
end
end
