% Copyright 2026 The MathWorks, Inc.

classdef WorkflowTestModel < rstar.Model
    %WorkflowTestModel Lightweight implementation of the shared workflow.

    methods
        function obj = WorkflowTestModel
            obj@rstar.Model(rstar.HLWOptions);
            obj.Name = "HLW";
        end
    end

    methods (Access=protected)
        function validateData(~, ~)
        end

        function stage = estimateStage1(~, ~)
            stage = struct("logLikelihood", -1);
        end

        function stage = estimateStage2(~, ~, ~)
            stage = struct("logLikelihood", -2);
        end

        function stage = estimateStage3(~, ~, ~, ~)
            stage = struct("logLikelihood", -3);
        end

        function lambda = estimateLambdaG(~, ~)
            lambda = 0.01;
        end

        function lambda = estimateLambdaZ(~, ~)
            lambda = 0.02;
        end
    end
end
