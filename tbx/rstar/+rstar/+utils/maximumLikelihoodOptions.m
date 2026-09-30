function options = maximumLikelihoodOptions(nvArgs)
%maximumLikelihoodOptions Return settings for state-space estimation.
%
%   options = rstar.utils.maximumLikelihoodOptions creates fmincon
%   settings used by the r-star estimators. Specify name-value arguments
%   from optim.options.Fmincon to override the project defaults.
%
%   Copyright 2026 The MathWorks, Inc.

arguments
    nvArgs.?optim.options.Fmincon
end

options = optimoptions(@fmincon, ...
    Algorithm = "interior-point", ...
    MaxIterations=5000, ...
    MaxFunctionEvaluations=5000, ...
    OptimalityTolerance=1e-8, ...
    UseParallel=true, ...
    ScaleProblem= true, ...
    Display="off");

propertyNames = fieldnames(nvArgs);
for index = 1:numel(propertyNames)
    options.(propertyNames{index}) = nvArgs.(propertyNames{index});
end
end
