%[text] # Recreate U.S. HLW2023 Inputs from FRED
%[text] Retrieve the four FRED series used for the U.S. core inputs and combine them with the published HLW COVID indicator.
%[text] ## Retrieve and transform data
%[text] Store a FRED API key in the MATLAB vault with `setSecret("FREDKEY", key)` before running this section.
%[text] **1. Get FRED connection**
fred = fredrs(getSecret("FREDKEY")) %[output:1ad83bc8]
%%
%[text] **2. Query the data**
gdp = quarterlySeries(fred, "GDPC1");
head(gdp) %[output:5010afd4]
pce = quarterlyAverage(fred, "PCEPILFE");
discountRate = quarterlySeries(fred, "INTDSRUSM193N");
fedFundsRate = quarterlySeries(fred, "FEDFUNDS");
%%
%[text] **3. Annualize and transform data**
discountRate.Value = annualizedEffectiveRate(discountRate.Value);
fedFundsRate.Value = annualizedEffectiveRate(fedFundsRate.Value);
discountRate = retime(discountRate, "quarterly", "mean");
fedFundsRate = retime(fedFundsRate, "quarterly", "mean");

discountRate.Properties.VariableNames = "discount";

data = synchronize(gdp, pce, fedFundsRate, "intersection");
data.Properties.VariableNames = ["gdp", "pce", "fedFunds"];
%[text] **Inflation**
inflation = 400 * [NaN; diff(log(data.pce))];
%[text] **Inflation expectations**
inflationExpectations = movmean(inflation, [3, 0]);
inflationExpectations(1:3) = NaN;
%[text] **Interest**
interest = data.fedFunds;
usesDiscountRate = data.Time < datetime(1965, 1, 1);
[hasDiscountRate, discountIndex] = ismember(data.Time(usesDiscountRate), discountRate.Time);
assert(all(hasDiscountRate), "The discount-rate series is missing an early quarterly observation.")
interest(usesDiscountRate) = discountRate.discount(discountIndex);
%[text] **Final data**
coreInputs = timetable(log(data.gdp), inflation, inflationExpectations, interest, RowTimes=data.Time, VariableNames=["gdp.log", "inflation", "inflation.expectations", "interest"]);
coreInputs = rmmissing(coreInputs);

head(coreInputs) %[output:6ae493cd]
%%
%[text] ## Assemble the estimator input table
%[text] The COVID indicator is a published HLW model input rather than a FRED series, so retrieve it from the current New York Fed workbook.
hlwUrl = "https://www.newyorkfed.org/medialibrary/media/research/economists/williams/data/Holston_Laubach_Williams_current_estimates.xlsx";
publishedInputs = readtable(hlwUrl, Sheet="US input data", VariableNamingRule="preserve", TextType="string");
head(publishedInputs) %[output:28ccb735]
covid = timetable(publishedInputs.("covid.ind"), RowTimes=publishedInputs.date, VariableNames="covid.ind");
hlwInputs = synchronize(coreInputs, covid, "intersection");
hlwInputs = timetable2table(hlwInputs, ConvertRowTimes=true);
hlwInputs.Properties.VariableNames(1) = {'date'};
hlwInputs %[output:91e5c979]
%%
%[text] ## Helper functions
function output = quarterlySeries(connection, seriesID)
observations = series(connection, seriesID, "observations");
observations = observations.observations{1};
output = timetable(observations.value, RowTimes=observations.date, VariableNames="Value");
end
function output = quarterlyAverage(connection, seriesID)
output = quarterlySeries(connection, seriesID);
output = retime(output, "quarterly", "mean");
end
function rate = annualizedEffectiveRate(rate)
rate = 100 * ((1 + rate / 36000).^365 - 1);
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:1ad83bc8]
%   data: {"dataType":"textualVariable","outputData":{"name":"fred","value":"  <a href=\"matlab:helpPopup('fredrs')\" style=\"font-weight:bold\">fredrs<\/a> with properties:\n\n    TimeOut: 200\n"}}
%---
%[output:5010afd4]
%   data: {"dataType":"text","outputData":{"text":"       <strong>Time<\/strong>        <strong>Value<\/strong> \n    <strong>___________<\/strong>    <strong>______<\/strong>\n\n    <strong>01-Jan-1947<\/strong>    2182.7\n    <strong>01-Apr-1947<\/strong>    2176.9\n    <strong>01-Jul-1947<\/strong>    2172.4\n    <strong>01-Oct-1947<\/strong>    2206.5\n    <strong>01-Jan-1948<\/strong>    2239.7\n    <strong>01-Apr-1948<\/strong>    2276.7\n    <strong>01-Jul-1948<\/strong>    2289.8\n    <strong>01-Oct-1948<\/strong>    2292.4\n\n","truncated":false}}
%---
%[output:6ae493cd]
%   data: {"dataType":"text","outputData":{"text":"       <strong>Time<\/strong>        <strong>gdp.log<\/strong>    <strong>inflation<\/strong>    <strong>inflation.expectations<\/strong>    <strong>interest<\/strong>\n    <strong>___________<\/strong>    <strong>_______<\/strong>    <strong>_________<\/strong>    <strong>______________________<\/strong>    <strong>________<\/strong>\n\n    <strong>01-Jan-1960<\/strong>    8.1654       1.2644             2.0878             4.1387 \n    <strong>01-Apr-1960<\/strong>      8.16       1.5121             1.9323             4.0157 \n    <strong>01-Jul-1960<\/strong>    8.1649       1.5648             1.6569             3.3257 \n    <strong>01-Oct-1960<\/strong>     8.152       1.3091             1.4126             3.0883 \n    <strong>01-Jan-1961<\/strong>    8.1587      0.68203              1.267             3.0883 \n    <strong>01-Apr-1961<\/strong>    8.1756       1.3109             1.2167             3.0883 \n    <strong>01-Jul-1961<\/strong>    8.1946       1.7357             1.2594             3.0883 \n    <strong>01-Oct-1961<\/strong>     8.214      0.95554              1.171             3.0883 \n\n","truncated":false}}
%---
%[output:28ccb735]
%   data: {"dataType":"text","outputData":{"text":"       <strong>date<\/strong>        <strong>gdp.log<\/strong>    <strong>inflation<\/strong>    <strong>inflation.expectations<\/strong>    <strong>interest<\/strong>    <strong>covid.ind<\/strong>\n    <strong>___________<\/strong>    <strong>_______<\/strong>    <strong>_________<\/strong>    <strong>______________________<\/strong>    <strong>________<\/strong>    <strong>_________<\/strong>\n\n    01-Jan-1960    8.1654       1.2595             2.0861             4.1387         0    \n    01-Apr-1960      8.16        1.519             1.9333             4.0169         0    \n    01-Jul-1960    8.1649       1.5588             1.6582              3.328         0    \n    01-Oct-1960     8.152       1.3092             1.4116             3.0883         0    \n    01-Jan-1961    8.1587      0.68332             1.2676             3.0883         0    \n    01-Apr-1961    8.1756       1.3137             1.2162             3.0883         0    \n    01-Jul-1961    8.1946       1.7287             1.2587             3.0883         0    \n    01-Oct-1961     8.214      0.96378             1.1724             3.0883         0    \n\n","truncated":false}}
%---
%[output:91e5c979]
%   data: {"dataType":"tabular","outputData":{"columnNames":["date","gdp.log","inflation","inflation.expectations","interest","covid.ind"],"columns":6,"dataTypes":["datetime","double","double","double","double","double"],"header":"266×6 table","name":"hlwInputs","rows":266,"type":"table","value":[["01-Jan-1960","8.1654","1.2644","2.0878","4.1387","0"],["01-Apr-1960","8.1600","1.5121","1.9323","4.0157","0"],["01-Jul-1960","8.1649","1.5648","1.6569","3.3257","0"],["01-Oct-1960","8.1520","1.3091","1.4126","3.0883","0"],["01-Jan-1961","8.1587","0.6820","1.2670","3.0883","0"],["01-Apr-1961","8.1756","1.3109","1.2167","3.0883","0"],["01-Jul-1961","8.1946","1.7357","1.2594","3.0883","0"],["01-Oct-1961","8.2140","0.9555","1.1710","3.0883","0"],["01-Jan-1962","8.2317","1.4782","1.3701","3.0883","0"],["01-Apr-1962","8.2407","1.5381","1.4269","3.0883","0"],["01-Jul-1962","8.2529","1.3125","1.3211","3.0883","0"],["01-Oct-1962","8.2562","0.7481","1.2692","3.0883","0"],["01-Jan-1963","8.2671","1.3220","1.2302","3.0883","0"],["01-Apr-1963","8.2782","1.5113","1.2235","3.0883","0"]]}}
%---
