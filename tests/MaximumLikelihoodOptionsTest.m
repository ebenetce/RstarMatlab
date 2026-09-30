% Copyright 2026 The MathWorks, Inc.

classdef MaximumLikelihoodOptionsTest < matlab.unittest.TestCase
    %MaximumLikelihoodOptionsTest Test shared state-space optimization settings.

    methods (Test)
        function testMatchesReplicationEvaluationBudget(testCase)
            options = rstar.utils.maximumLikelihoodOptions();

            testCase.verifyEqual(options.MaxIterations, 5000);
            testCase.verifyEqual(options.MaxFunctionEvaluations, 5000);
            testCase.verifyEqual(options.OptimalityTolerance, 1e-8, AbsTol=eps);
        end

        function testAcceptsModelSpecificTolerance(testCase)
            options = rstar.utils.maximumLikelihoodOptions(OptimalityTolerance=1e-15);

            testCase.verifyEqual(options.OptimalityTolerance, 1e-15, AbsTol=eps);
        end

        function testAcceptsCustomOptimizationBudget(testCase)
            options = rstar.utils.maximumLikelihoodOptions( ...
                MaxIterations=10000, MaxFunctionEvaluations=25000, UseParallel=false);

            testCase.verifyEqual(options.MaxIterations, 10000);
            testCase.verifyEqual(options.MaxFunctionEvaluations, 25000);
            testCase.verifyEqual(options.UseParallel, "off");
        end

        function testAcceptsAllFminconNameValueOptions(testCase)
            options = rstar.utils.maximumLikelihoodOptions( ...
                ConstraintTolerance=1e-7, StepTolerance=1e-9);

            testCase.verifyEqual(options.ConstraintTolerance, 1e-7, AbsTol=eps);
            testCase.verifyEqual(options.StepTolerance, 1e-9, AbsTol=eps);
        end
    end
end
