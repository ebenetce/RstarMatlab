% Copyright 2026 The MathWorks, Inc.

classdef HLWModelTest < matlab.unittest.TestCase
    %HLWModelTest Integration tests for the original HLW model.

    methods (Test, TestTags = {'Integration'})
        function testReturnsNonnegativeScaleParameters(testCase)
            files = setupPublishedData;
            data = readtable(files.HLW, Sheet="US input data", ...
                VariableNamingRule="preserve", TextType="string");

            optimizationOptions = rstar.utils.maximumLikelihoodOptions( ...
                Algorithm="interior-point");
            opts = rstarOptions("HLW", Verbose=false, ...
                OptimizationOptions=optimizationOptions);
            result = rstar("HLW", opts).estimate(data);

            testCase.verifyGreaterThanOrEqual(result.stage1.theta(6:8), 0);
            testCase.verifyGreaterThanOrEqual(result.stage2.theta(8:10), 0);
            testCase.verifyGreaterThanOrEqual(result.stage3.theta(6:8), 0);
            testCase.verifyTrue(isfield(result.stage1.optimization, "preliminary"));
            testCase.verifyTrue(isfield(result.stage2.optimization, "preliminary"));
            testCase.verifyTrue(isfield(result.stage3.optimization, "preliminary"));
            testCase.verifyTrue(isfield(result.stage1.optimization, "final"));
            testCase.verifyTrue(isfield(result.stage2.optimization, "final"));
            testCase.verifyTrue(isfield(result.stage3.optimization, "final"));
        end
    end
end
