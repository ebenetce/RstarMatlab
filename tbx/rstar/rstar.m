function model = rstar(modelName, options)
%rstar Construct a model object for a named published r-star specification.
%
%   model = rstar(modelName) uses default model-specific settings.
%   model = rstar(modelName, options) uses options returned by
%   rstarOptions. Call estimate(model, data) to run the estimator.
%
%   Copyright 2026 The MathWorks, Inc.

    arguments
        modelName (1,1) string {mustBeMember(modelName, ["LW", "LW2023", "HLW", "HLW2023"])}
        options (1,1) rstar.Options = rstarOptions(modelName)
    end
  
    options.validateFor(modelName);

    switch upper(modelName)
        case "LW"
            model = rstar.LWModel(options);
        case "LW2023"
            model = rstar.LW2023Model(options);
        case "HLW"
            model = rstar.HLWModel(options);
        case "HLW2023"
            model = rstar.HLW2023Model(options);
    end
end
