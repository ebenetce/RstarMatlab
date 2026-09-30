# Rstar MATLAB replication workspace

This workspace contains the supplied R replication sources and an in-progress
MATLAB implementation of the Holston-Laubach-Williams (HLW) natural-rate
estimator.

## What runs today

`rstar("LW").estimate(data)` and `rstar("HLW").estimate(data)` run the
three-stage original estimators. LW requires the supplied replication
variables `gdp.log`, `inflation`, `inflation.expectations`,
`oil.price.inflation`, `import.price.inflation`, and `interest`.

- `gdp.log`
- `inflation`
- `inflation.expectations`
- `interest`

Use `data/rstar.data.us.csv` as the bundled HLW U.S. input. This requires
Econometrics Toolbox and Optimization Toolbox.

The full LW-2023 and HLW-2023 estimators are available through their public
model interfaces. LW-2023 additionally requires `Date` and `covid.ind`; use
`resources/Laubach_Williams_current_estimates.xlsx`, sheet `input data`, as
the bundled current LW vintage.

## Public interface

Construct each published specification through the two top-level factories:

```matlab
options = rstarOptions("HLW2023", SampleEnd=datetime(2024, 1, 1));
model = rstar("HLW2023", options);
result = model.estimate(data);
```

`rstarOptions` returns settings for the selected model and `rstar` returns
its corresponding model class. The supported model identities are `"LW"`,
`"LW2023"`, `"HLW"`, and `"HLW2023"`.

For the COVID-adjusted models, pass an `optim.options.Fmincon` object through
`OptimizationOptions` to change the maximum-likelihood optimizer settings.
`maximumLikelihoodOptions` accepts every public `optim.options.Fmincon`
name-value option while retaining the project defaults for unspecified values:

```matlab
optimizationOptions = rstar.utils.maximumLikelihoodOptions( ...
    MaxIterations=20000, MaxFunctionEvaluations=50000);
options = rstarOptions("HLW2023", OptimizationOptions=optimizationOptions);
result = rstar("HLW2023", options).estimate(data);
```

## Replication status

| Variant | MATLAB status | R reference |
| --- | --- | --- |
| HLW 2017-style U.S. model | Runnable, smoke-tested | `HLW_Code/` |
| Laubach-Williams (LW) | Runnable through the public model interface | `LW_replication/` |
| Laubach-Williams 2023 | Runnable through the public model interface | `LW_2023_Replication_Code/` |
| HLW 2023 COVID-adjusted model | Runnable through the public model interface; validated against bundled R fixture | `HLW_2023_Replication_Code/` |

Source-generated U.S. HLW-2023 fixtures are under
`HLW_2023_Replication_Code/output/`. They were produced from the bundled R
replication in a disposable R 4.4.3 container, with only the optional
Monte-Carlo standard errors disabled.

The planned MATLAB implementation uses Econometrics Toolbox `ssm` with a
time-varying observation-noise map for the kappa terms. The Bayesian `bssm`
and `bnlssm` objects are not appropriate for this maximum-likelihood
replication.

## Layout

- `tbx/rstar/+rstar/` — MATLAB package implementation
- `examples/` — portable entry points
- `tests/` — MATLAB unit and integration tests
- `data/` — bundled MATLAB input data
- `LW_replication/`, `HLW_Code/`, `HLW_2023_Replication_Code/` — source R
  replications retained as references
