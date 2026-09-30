# Rstar toolbox

Rstar estimates the natural rate of interest with the Laubach-Williams (LW)
and Holston-Laubach-Williams (HLW) specifications. The toolbox provides the
original models and their COVID-adjusted 2023 variants.

The [New York Fed r-star page](https://www.newyorkfed.org/research/policy/rstar)
publishes current and real-time estimate workbooks. The examples below use the
current U.S. inputs from that page to reproduce the corresponding filtered
natural-rate and trend-growth series.

## Requirements

Rstar requires MATLAB, Econometrics Toolbox, and Optimization Toolbox.

## Models

* [LW](LW.md) is the original Laubach-Williams specification.
* [LW2023](LW2023.md) is the COVID-adjusted current LW specification.
* [HLW](HLW.md) is the original Holston-Laubach-Williams specification.
* [HLW2023](HLW2023.md) is the COVID-adjusted HLW specification.

## Reproduce the current U.S. estimates

The COVID-adjusted HLW model uses the U.S. input sheet in the corresponding
HLW workbook. The larger optimization budget below avoids the stage-two
non-convergence warning that can occur for the latest vintage.

```matlab
if isempty(gcp('nocreate')), parpool threads, end
hlwUrl = "https://www.newyorkfed.org/medialibrary/media/research/economists/williams/data/Holston_Laubach_Williams_current_estimates.xlsx";
hlwData = readtable(hlwUrl, Sheet="US input data", VariableNamingRule="preserve");

optimizer = rstar.utils.maximumLikelihoodOptions( MaxIterations=20000, MaxFunctionEvaluations=50000);
hlwOptions = rstarOptions("HLW2023", OptimizationOptions=optimizer);
mdl = rstar("HLW2023", hlwOptions);
hlwResults = mdl.estimate(hlwData);

hlwDates = hlwData.date(5:end);
figure(Color="white")
hold on
plot(hlwDates, hlwResults.stage3.rstarFiltered, LineWidth=2, DisplayName="Natural rate")
plot(hlwDates, hlwResults.stage3.trendFiltered, LineWidth=2, DisplayName="Trend growth")
title("Current U.S. Holston-Laubach-Williams estimates")
xlabel("Quarter")
ylabel("Percent")
xlim([datetime(1985,1,1), hlwDates(end)])
ylim([0, 4])
grid on
box on
legend(Location="southwest")
```

We can then add different countries to the mix
```matlab
caData = readtable(hlwUrl, Sheet="CA input data", VariableNamingRule="preserve");
eaData = readtable(hlwUrl, Sheet="EA input data", VariableNamingRule="preserve");

hlwOptions.Verbose = false;
caResults = mdl.estimate(caData);

kappaInputs = rstar.CovidAdjustedOptions.defaultKappaInputs();
kappaInputs(end+1, :) = {"kappa2023", datetime(2023,1,1), datetime(2023,10,1), 1, 1, Inf};
optimizer = rstar.utils.maximumLikelihoodOptions( MaxIterations=20000, MaxFunctionEvaluations=50000);
options = rstarOptions("HLW2023", KappaInputs=kappaInputs, OptimizationOptions=optimizer, Verbose = false);

eaResults = rstar("HLW2023", options).estimate(eaData);

US = timetable(hlwResults.stage3.rstarFiltered, ...
 hlwResults.stage3.trendFiltered, hlwResults.stage3.outputGapFiltered, RowTimes = hlwDates, VariableNames = ["Natural Rate of Interest", "Trend Growth", "Output Gap"]);

CA = timetable(caResults.stage3.rstarFiltered, ...
 caResults.stage3.trendFiltered, caResults.stage3.outputGapFiltered, RowTimes = hlwDates, VariableNames = ["Natural Rate of Interest", "Trend Growth", "Output Gap"]);

EA = timetable(eaResults.stage3.rstarFiltered, ...
 eaResults.stage3.trendFiltered, eaResults.stage3.outputGapFiltered, RowTimes = eaData.date(5:end), VariableNames = ["Natural Rate of Interest", "Trend Growth", "Output Gap"]);

figure('Color','w')
ax = stackedplot(US, CA, EA, LegendLabels = ["United States", "Canada", "Euro Area"])
grid on
ax.AxesProperties(1).YLimits = [0,8];
ax.AxesProperties(2).YLimits = [0,6];
ax.AxesProperties(3).YLimits = [-10,10];
```


The New York Fed periodically revises the source workbooks. Rerun these
examples to reproduce the then-current release. Rstar is an independent
MATLAB implementation; the New York Fed does not distribute or endorse it.

## Estimation settings

COVID-adjusted models infer `SampleStart` when it is `NaT`, using the first
available date and the model's required presample. They similarly infer
`SampleEnd` as the last available date. Set either option explicitly to use a
different sample.

All models accept an `optim.options.Fmincon` object through
`OptimizationOptions`. The helper retains Rstar defaults while accepting every
public `fmincon` name-value setting:

```matlab 
optimizer = rstar.utils.maximumLikelihoodOptions( ...
    MaxIterations=20000, MaxFunctionEvaluations=50000); 
options = rstarOptions("HLW2023", OptimizationOptions=optimizer);  
``` 

## References

Laubach, T., and J. C. Williams (2003). "Measuring the Natural Rate of
Interest." *Review of Economics and Statistics*, 85(4), 1063-1070.

Holston, K., T. Laubach, and J. C. Williams (2017). "Measuring the Natural
Rate of Interest: International Trends and Determinants." *Journal of
International Economics*, 108(S1), S59-S75.

Holston, K., T. Laubach, and J. C. Williams (2023). "Measuring the Natural
Rate of Interest after COVID-19." *Federal Reserve Bank of New York Staff
Reports*, no. 1063.
