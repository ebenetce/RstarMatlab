% Copyright 2026 The MathWorks, Inc.

classdef ModelWorkflowTest < matlab.unittest.TestCase
    %ModelWorkflowTest Test the shared three-stage model workflow.

    methods (Test)
        function testVerboseWorkflowReportsEachStage(testCase)
            model = WorkflowTestModel;

            output = evalc("result = model.estimate(table);");

            testCase.verifyEqual(result.lambdaG, 0.01, AbsTol=eps);
            testCase.verifyEqual(result.lambdaZ, 0.02, AbsTol=eps);
            testCase.verifyTrue(contains(output, "Estimating HLW Stage 1..."));
            testCase.verifyTrue(contains(output, "lambda_g = 0.010000"));
            testCase.verifyTrue(contains(output, "Estimating HLW Stage 2..."));
            testCase.verifyTrue(contains(output, "lambda_z = 0.020000"));
            testCase.verifyTrue(contains(output, "Estimating HLW Stage 3..."));
        end

        function testSilentWorkflowDoesNotWriteOutput(testCase)
            model = WorkflowTestModel;
            model.Verbose = false;

            output = evalc("result = model.estimate(table);");

            testCase.verifyEmpty(output);
        end
    end
end
