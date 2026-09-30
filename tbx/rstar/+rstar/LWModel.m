classdef LWModel < rstar.Model
    %LWModel Original Laubach-Williams specification.
    %
    %   Copyright 2026 The MathWorks, Inc.
    
    methods
        function obj = LWModel(options)
            arguments
                options (1,1) rstar.LWOptions
            end

            obj@rstar.Model(options);
            obj.Name = "LW";
        end
    end
    methods (Access = protected)
        function validateData(~, data)
            requiredVariables = ["gdp.log", "inflation", ...
                "inflation.expectations", "oil.price.inflation", ...
                "import.price.inflation", "interest"];
            missingVariables = setdiff(requiredVariables, ...
                string(data.Properties.VariableNames));
            if ~isempty(missingVariables)
                error("rstar:LWModel:MissingVariables", ...
                    "Input data must contain: %s.", ...
                    strjoin(requiredVariables, ", "));
            end
            if height(data) < 17
                error("rstar:LWModel:InsufficientData", ...
                    "Input data must include the eight-quarter presample.");
            end
        end
        function stage = estimateStage1(obj, data)
            stage = rstar.estimateLWStage(data, obj.Options, false, 1);
        end

        function stage = estimateStage2(obj, data, lambdaG)
            stage = rstar.estimateLWStage(data, obj.Options, false, 2, lambdaG);
        end

        function stage = estimateStage3(obj, data, lambdaG, lambdaZ)
            stage = rstar.estimateLWStage(data, obj.Options, false, 3, lambdaG, lambdaZ);
        end
    end
end
