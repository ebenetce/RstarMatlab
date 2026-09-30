classdef LW2023Model < rstar.Model
    %LW2023Model Current Laubach-Williams specification.
    %
    %   Copyright 2026 The MathWorks, Inc.

    properties (Constant, Access=private)
        RequiredPresampleQuarters = 8
    end

    methods
        function obj = LW2023Model(options)
            %LW2023Model Construct the current COVID-adjusted LW estimator.

            arguments
                options (1,1) rstar.LW2023Options
            end

            obj@rstar.Model(options);
            obj.Name = "LW2023";
        end
    end

    methods (Access = protected)
        function validateData(~, data)
            requiredVariables = ["gdp.log", "inflation", ...
                "inflation.expectations", "oil.price.inflation", ...
                "import.price.inflation", "interest", "covid.ind"];
            missingVariables = setdiff(requiredVariables, ...
                string(data.Properties.VariableNames));
            if ~isempty(missingVariables)
                error("rstar:LW2023Model:MissingVariables", ...
                    "Input data must contain: %s.", ...
                    strjoin(requiredVariables, ", "));
            end
        end

        function data = prepareData(obj, data)
            [data, obj.Options] = rstar.utils.prepareQuarterlyData(data, obj.Options, ...
                obj.RequiredPresampleQuarters);
        end

        function stage = estimateStage1(obj, data)
            stage = rstar.estimateLWStage(data, obj.Options, true, 1);
        end

        function stage = estimateStage2(obj, data, lambdaG)
            stage = rstar.estimateLWStage(data, obj.Options, true, 2, lambdaG);
        end

        function stage = estimateStage3(obj, data, lambdaG, lambdaZ)
            stage = rstar.estimateLWStage(data, obj.Options, true, 3, lambdaG, lambdaZ);
        end
    end
end
