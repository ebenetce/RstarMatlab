% Copyright 2026 The MathWorks, Inc.

classdef CovidAdjustedOptionsTest < matlab.unittest.TestCase
    %CovidAdjustedOptionsTest Unit tests for shared COVID-adjusted settings.

    methods (Test)
        function testModelSpecificDefaults(testCase)
            hlwOptions = rstar.HLW2023Config();
            lwOptions = rstar.LW2023Options();

            testCase.verifyEqual(hlwOptions.ModelName, "HLW2023");
            testCase.verifyEqual(lwOptions.ModelName, "LW2023");
            testCase.verifyTrue(isnat(hlwOptions.SampleEnd));
            testCase.verifyTrue(isnat(lwOptions.SampleEnd));
            testCase.verifyEqual(hlwOptions.KappaInputs, lwOptions.KappaInputs);
        end

        function testNameValueOverride(testCase)
            options = rstar.LW2023Options(SampleStart=datetime(1970, 1, 1), ...
                SampleEnd=datetime(2025, 1, 1), UseKappa=false);

            testCase.verifyEqual(options.SampleStart, datetime(1970, 1, 1));
            testCase.verifyEqual(options.SampleEnd, datetime(2025, 1, 1));
            testCase.verifyFalse(options.UseKappa);
        end

        function testAcceptsCustomOptimizationOptions(testCase)
            optimizationOptions = rstar.utils.maximumLikelihoodOptions( ...
                MaxIterations=10000, MaxFunctionEvaluations=25000);
            options = rstar.HLW2023Config(OptimizationOptions=optimizationOptions);

            testCase.verifyEqual(options.OptimizationOptions.MaxIterations, 10000);
            testCase.verifyEqual(options.OptimizationOptions.MaxFunctionEvaluations, 25000);
        end

        function testFixedPhiIsRequiredWhenNotEstimated(testCase)
            testCase.verifyError(@() rstar.HLW2023Config(EstimatePhi=false), ...
                "rstar:CovidAdjustedOptions:MissingFixedPhi");
        end
    end
end
