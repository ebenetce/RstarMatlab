% Copyright 2026 The MathWorks, Inc.

classdef OlsTest < matlab.unittest.TestCase
    %OlsTest Unit tests for the shared ordinary least-squares helper.

    methods (Test)
        function testReturnsCoefficientsResidualsAndStandardDeviation(testCase)
            design = [ones(4,1), (1:4)'];
            response = [2.1; 4.0; 5.9; 8.2];

            [coefficients, residuals, standardDeviation] = ...
                rstar.utils.ols(design, response);

            testCase.verifyEqual(coefficients, [-0.0; 2.02], AbsTol=1e-12);
            testCase.verifyEqual(residuals, [0.08; -0.04; -0.16; 0.12], ...
                AbsTol=1e-12);
            testCase.verifyEqual(standardDeviation, sqrt(0.048 / 2), ...
                AbsTol=1e-12);
        end

        function testRejectsIncompatibleRows(testCase)
            design = ones(3,1);
            response = ones(4,1);

            testCase.verifyError(@() rstar.utils.ols(design, response), ...
                "rstar:utils:ols:IncompatibleSize");
        end
    end
end
