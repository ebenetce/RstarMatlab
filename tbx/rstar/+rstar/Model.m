classdef (Abstract) Model < handle
    %Model Abstract interface implemented by each published r-star model.
    %
    %   Copyright 2026 The MathWorks, Inc.

    properties
        Options = []
        Name string = ""
    end

    properties
        Verbose (1,1) logical = true
    end

    properties (SetAccess = private)
        Data = table
        Result = []
        Stage1 = []
        Stage2 = []
        Stage3 = []
        IsEstimated (1,1) logical = false
    end

    methods
        function obj = Model(options)
            %Model Construct a reusable model from compatible options.

            arguments
                options (1,1) rstar.Options
            end

            obj.Options = options;
            obj.Verbose = options.Verbose;
        end

        function result = estimate(obj, data)
            %estimate Run the model on one data vintage.

            arguments
                obj (1,1) rstar.Model
                data {mustBeA(data, ["table", "timetable"])}
            end

            obj.validateData(data);
            obj.Options.validateFor(obj.Name);
            estimationData = obj.prepareData(data);

            obj.logStageStart(1);
            stage1 = obj.estimateStage1(estimationData);
            lambdaG = obj.estimateLambdaG(stage1);
            obj.logStageComplete(1, stage1.logLikelihood, lambdaG);

            obj.logStageStart(2);
            stage2 = obj.estimateStage2(estimationData, lambdaG);
            lambdaZ = obj.estimateLambdaZ(stage2);
            obj.logStageComplete(2, stage2.logLikelihood, lambdaZ);

            obj.logStageStart(3);
            stage3 = obj.estimateStage3(estimationData, lambdaG, lambdaZ);
            obj.logStageComplete(3, stage3.logLikelihood);

            result = struct("stage1", stage1, "stage2", stage2, ...
                "stage3", stage3, "lambdaG", lambdaG, "lambdaZ", lambdaZ);
            result.model = obj.Name;
            result.options = obj.Options;

            obj.Data = data;
            obj.Result = result;
            obj.Stage1 = result.stage1;
            obj.Stage2 = result.stage2;
            obj.Stage3 = result.stage3;
            obj.IsEstimated = true;
        end
    end

    methods (Abstract, Access = protected)
        validateData(obj, data)
        stage = estimateStage1(obj, data)
        stage = estimateStage2(obj, data, lambdaG)
        stage = estimateStage3(obj, data, lambdaG, lambdaZ)
    end

    methods (Access = protected)
        function data = prepareData(~, data)
        end

        function lambda = estimateLambdaG(~, stage)
            lambda = rstar.utils.expwaldstat(400 * diff(stage.potentialSmoothed), ...
                ones(numel(stage.potentialSmoothed) - 1, 1));
        end

        function lambda = estimateLambdaZ(~, stage)
            weights = 1 ./ stage.kappa.^2;
            lambda = rstar.utils.expwaldstat(stage.y, stage.x, Weights=weights);
        end

        function logStageStart(obj, stageNumber)
            if obj.Verbose
                fprintf("Estimating %s Stage %d...\n", obj.Name, stageNumber);
            end
        end

        function logStageComplete(obj, stageNumber, logLikelihood, lambda)
            if ~obj.Verbose
                return
            end
            if nargin < 4
                fprintf("Stage %d complete: log likelihood = %.4f\n", ...
                    stageNumber, logLikelihood);
            elseif stageNumber == 1
                fprintf("Stage 1 complete: log likelihood = %.4f, lambda_g = %.6f\n", ...
                    logLikelihood, lambda);
            else
                fprintf("Stage 2 complete: log likelihood = %.4f, lambda_z = %.6f\n", ...
                    logLikelihood, lambda);
            end
        end
    end
end
