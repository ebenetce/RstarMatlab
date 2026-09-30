# Holston-Laubach-Williams (HLW)

`HLW` implements the original Holston-Laubach-Williams natural-rate
estimator.

## Input data

Pass a table with these variables:

* `gdp.log`
* `inflation`
* `inflation.expectations`
* `interest`

## Reproduce the current input vintage

The current New York Fed HLW workbook supplies all required variables. The
original model ignores the additional date and COVID-indicator columns.

```matlab
dataUrl = "https://www.newyorkfed.org/medialibrary/media/research/economists/williams/data/Holston_Laubach_Williams_current_estimates.xlsx";
data = readtable(dataUrl, Sheet="US input data", VariableNamingRule="preserve");
results = rstar("HLW", rstarOptions("HLW", Verbose=false)).estimate(data);
dates = data.date(5:end);

figure(Color="white")
hold on
plot(dates, results.stage3.rstarFiltered, LineWidth=2, DisplayName="Natural rate")
plot(dates, results.stage3.trendFiltered, LineWidth=2, DisplayName="Trend growth")
title("U.S. Holston-Laubach-Williams estimates")
xlabel("Quarter")
ylabel("Percent")
xlim([datetime(1985,1,1), dates(end)])
ylim([0, 4])
grid on
box on
legend(Location="southwest")
```

The stage-three result includes filtered and smoothed natural-rate, trend, and
`z` estimates.

## Reference

Holston, K., T. Laubach, and J. C. Williams (2017). "Measuring the Natural
Rate of Interest: International Trends and Determinants." *Journal of
International Economics*, 108(S1), S59-S75.
