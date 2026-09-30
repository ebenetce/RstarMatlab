% Copyright 2026 The MathWorks, Inc.

%% Recreate the U.S. HLW-2023 inputs from FRED
%
% This script retrieves the four FRED series used for the U.S. core inputs:
% GDPC1, PCEPILFE, INTDSRUSM193N, and FEDFUNDS. Store a FRED API key in
% the MATLAB vault with setSecret("FREDKEY", key) before running it.
%
% The COVID indicator is a published HLW model input, not a FRED series;
% this script obtains it from the current HLW workbook to form a complete
% estimator input table.

fred = fredrs(getSecret("FREDKEY"));

gdp = quarterlySeries(fred, "GDPC1");
pce = quarterlyAverage(fred, "PCEPILFE");
discountRate = quarterlySeries(fred, "INTDSRUSM193N");
fedFundsRate = quarterlySeries(fred, "FEDFUNDS");
discountRate.Value = annualizedEffectiveRate(discountRate.Value);
fedFundsRate.Value = annualizedEffectiveRate(fedFundsRate.Value);
discountRate = retime(discountRate, "quarterly", "mean");
fedFundsRate = retime(fedFundsRate, "quarterly", "mean");

gdp.Properties.VariableNames = "gdp";
pce.Properties.VariableNames = "pce";
discountRate.Properties.VariableNames = "discount";
fedFundsRate.Properties.VariableNames = "fedFunds";
data = synchronize(gdp, pce, fedFundsRate, "intersection");

inflation = 400 * [NaN; diff(log(data.pce))];
inflationExpectations = movmean(inflation, [3, 0]);
inflationExpectations(1:3) = NaN;
interest = data.fedFunds;
usesDiscountRate = data.Time < datetime(1965, 1, 1);
[hasDiscountRate, discountIndex] = ismember(data.Time(usesDiscountRate), ...
    discountRate.Time);
assert(all(hasDiscountRate), ...
    "The discount-rate series is missing an early quarterly observation.")
interest(usesDiscountRate) = discountRate.discount(discountIndex);

coreInputs = timetable(log(data.gdp), inflation, inflationExpectations, ...
    interest, RowTimes=data.Time, VariableNames=["gdp.log", "inflation", ...
    "inflation.expectations", "interest"]);
coreInputs = rmmissing(coreInputs);

hlwUrl = "https://www.newyorkfed.org/medialibrary/media/research/" + ...
    "economists/williams/data/Holston_Laubach_Williams_current_estimates.xlsx";
publishedInputs = readtable(hlwUrl, Sheet="US input data", ...
    VariableNamingRule="preserve", TextType="string");
covid = timetable(publishedInputs.("covid.ind"), ...
    RowTimes=publishedInputs.date, VariableNames="covid.ind");

hlwInputs = synchronize(coreInputs, covid, "intersection");
hlwInputs = timetable2table(hlwInputs, ConvertRowTimes=true);
hlwInputs.Properties.VariableNames(1) = {'date'};
hlwInputs

function output = quarterlySeries(connection, seriesID)
observations = series(connection, seriesID, "observations");
observations = observations.observations{1};
output = timetable(observations.value, RowTimes=observations.date, ...
    VariableNames="Value");
output = sortrows(output);
end

function output = quarterlyAverage(connection, seriesID)
output = quarterlySeries(connection, seriesID);
output = retime(output, "quarterly", "mean");
end

function rate = annualizedEffectiveRate(rate)
rate = 100 * ((1 + rate / 36000).^365 - 1);
end
