classdef (Abstract) Options
    %Options Abstract base class for model-specific estimator settings.
    %
    %   Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = protected)
        ModelName string = ""
    end

    properties
        Verbose (1,1) logical = true
        OptimizationOptions (1,1) optim.options.Fmincon = ...
            rstar.utils.maximumLikelihoodOptions()
    end

    methods
        function validateFor(obj, requestedModel)
            %validateFor Confirm that settings belong to a requested model.

            arguments
                obj (1,1) rstar.Options
                requestedModel (1,1) string
            end

            if ~strcmpi(obj.ModelName, requestedModel)
                error("rstar:Options:IncompatibleModel", ...
                    "Options for %s cannot be used with %s.", ...
                    obj.ModelName, requestedModel);
            end
        end
    end
end
