# Laubach-Williams (LW)

`LW` implements the original Laubach-Williams natural-rate estimator.

## Input data

Pass a table containing these variables:

* `gdp.log`
* `inflation`
* `inflation.expectations`
* `oil.price.inflation`
* `import.price.inflation`
* `interest`

The input must include at least eight presample quarters and nine estimation
quarters.

## Reproduce the current input vintage

The current New York Fed LW workbook supplies all required variables. The
original model ignores the additional date and COVID-indicator columns.

```matlab
dataUrl = "https://www.newyorkfed.org/medialibrary/media/research/economists/williams/data/Laubach_Williams_current_estimates.xlsx";
data = readtable(dataUrl, Sheet="input data", VariableNamingRule="preserve");

results = rstar("LW", rstarOptions("LW")).estimate(data);
dates = data.Date(9:end);

figure(Color="white")
hold on
plot(dates, results.stage3.rstarFiltered, LineWidth=2, DisplayName="Natural rate")
plot(dates, results.stage3.trendFiltered, LineWidth=2, DisplayName="Trend growth")
title("U.S. Laubach-Williams estimates")
xlabel("Quarter")
ylabel("Percent")
xlim([datetime(1985,1,1), dates(end)])
ylim([0, 4])
grid on
box on
legend(Location="southwest")
```

`results.stage3` contains `rstarFiltered`, `rstarSmoothed`,
`trendFiltered`, `trendSmoothed`, `zFiltered`, and `zSmoothed`.

## Reference

Laubach, T., and J. C. Williams (2003). "Measuring the Natural Rate of
Interest." *Review of Economics and Statistics*, 85(4), 1063-1070.
