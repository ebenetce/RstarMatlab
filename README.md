<!-- Copyright 2026 The MathWorks, Inc. -->

# Rstar

Rstar is a MATLAB toolbox for estimating the natural rate of interest using
the Laubach-Williams (LW) and Holston-Laubach-Williams (HLW) models, including
their COVID-adjusted 2023 specifications.

The toolbox is an independent MATLAB implementation. Current and real-time
published inputs and estimates are provided by the
[Federal Reserve Bank of New York](https://www.newyorkfed.org/research/policy/rstar).

## Requirements

- MATLAB R2026a or newer
- Econometrics Toolbox
- Optimization Toolbox

The optional FRED input-recreation example also requires Datafeed Toolbox and
a FRED API key stored in the MATLAB vault:

```matlab
setSecret("FREDKEY", "your-fred-api-key")
```

## Install

Install the packaged toolbox from a release, or clone this repository and add
the package folder to the MATLAB path:

```matlab
addpath("tbx/rstar")
```

## Quick start

```matlab
url = "https://www.newyorkfed.org/medialibrary/media/research/" + ...
    "economists/williams/data/Holston_Laubach_Williams_current_estimates.xlsx";
data = readtable(url, Sheet="US input data", ...
    VariableNamingRule="preserve", TextType="string");

optimizer = rstar.utils.maximumLikelihoodOptions(ScaleProblem=true);
options = rstarOptions("HLW2023", OptimizationOptions=optimizer, ...
    Verbose=false);
results = rstar("HLW2023", options).estimate(data);
```

For HLW2023, `ScaleProblem=true` improves conditioning of the constrained
maximum-likelihood problem and reproduces the published Canada solution with
the interior-point algorithm.

See [GettingStarted.m](tbx/doc/mfiles/GettingStarted.m) for complete U.S.,
Canada, and euro-area examples. The companion
[RecreateHLW2023USInputFromFRED.m](tbx/doc/mfiles/RecreateHLW2023USInputFromFRED.m)
rebuilds the U.S. core input series with `fredrs`.

## Models

| Model | Description |
| --- | --- |
| `LW` | Original Laubach-Williams model |
| `HLW` | Original Holston-Laubach-Williams model |
| `LW2023` | COVID-adjusted Laubach-Williams model |
| `HLW2023` | COVID-adjusted Holston-Laubach-Williams model |

Create a model with `rstar(modelName, options)` and configuration with
`rstarOptions(modelName)`.

## Test and package

Tests download the current NY Fed workbooks into a temporary cache on first
use; no published Excel fixture is required in the repository.

```matlab
buildtool test
buildtool package
```

`buildtool package` runs code checks, tests, documentation generation, and
creates `release/Rstar.mltbx`.

## Continuous integration

GitHub Actions runs the test suite on pushes and pull requests. Pushing a
semantic-version tag such as `v1.0.0` builds the toolbox and uploads the
`.mltbx` file as a workflow artifact. Configure the repository
`MLM_LICENSE_FILE` secret when the selected MATLAB installation requires a
license server or license file.

## References

- Laubach, T., and J. C. Williams (2003), “Measuring the Natural Rate of
  Interest,” *Review of Economics and Statistics*, 85(4), 1063–1070.
- Holston, K., T. Laubach, and J. C. Williams (2017), “Measuring the Natural
  Rate of Interest: International Trends and Determinants,” *Journal of
  International Economics*, 108(S1), S59–S75.
- Holston, K., T. Laubach, and J. C. Williams (2023), “Measuring the Natural
  Rate of Interest after COVID-19,” *Federal Reserve Bank of New York Staff
  Reports*, no. 1063.
