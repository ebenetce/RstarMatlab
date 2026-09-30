% Copyright 2026 The MathWorks, Inc.

classdef KappaUtilitiesTest < matlab.unittest.TestCase
    %KappaUtilitiesTest Unit tests for shared kappa utilities.

    methods (Test)
        function testAppendKappaParameters(testCase)
            kappaInputs = rstar.CovidAdjustedOptions.defaultKappaInputs();
            [parameters, lowerBounds, upperBounds, schedule] = ...
                rstar.utils.appendKappaParameters([2, 3], [-Inf, -Inf], ...
                [Inf, Inf], 12, KappaInputs=kappaInputs, ...
                SampleStart=datetime(2020, 1, 1), UseKappa=true);

            testCase.verifyEqual(parameters, [2, 3, 1, 1, 1], AbsTol=0);
            testCase.verifyEqual(lowerBounds, [-Inf, -Inf, 1, 1, 1], AbsTol=0);
            testCase.verifyEqual(upperBounds, [Inf, Inf, Inf, Inf, Inf], AbsTol=0);
            testCase.verifyEqual(schedule, [0; 3; 3; 3; 4; 4; 4; 4; 5; 5; 5; 5], ...
                AbsTol=0);
        end

        function testAppendKappaParametersWhenDisabled(testCase)
            kappaInputs = rstar.CovidAdjustedOptions.defaultKappaInputs();
            [parameters, lowerBounds, upperBounds, schedule] = ...
                rstar.utils.appendKappaParameters(2, -Inf, Inf, 8, ...
                KappaInputs=kappaInputs, SampleStart=datetime(2020, 1, 1), ...
                UseKappa=false);

            testCase.verifyEqual(parameters, 2, AbsTol=0);
            testCase.verifyEqual(lowerBounds, -Inf, AbsTol=0);
            testCase.verifyEqual(upperBounds, Inf, AbsTol=0);
            testCase.verifyEqual(schedule, zeros(8, 1), AbsTol=0);
        end

        function testSupportsExplicitPartialYearSchedule(testCase)
            kappaInputs = table("kappa2021Q2-Q3", datetime(2021, 4, 1), ...
                datetime(2021, 7, 1), 1, 1, Inf, ...
                VariableNames=["Name", "StartDate", "EndDate", "InitialValue", ...
                "LowerBound", "UpperBound"]);
            [parameters, ~, ~, schedule] = rstar.utils.appendKappaParameters( ...
                2, -Inf, Inf, 8, KappaInputs=kappaInputs, ...
                SampleStart=datetime(2021, 1, 1), UseKappa=true);

            testCase.verifyEqual(parameters, [2, 1], AbsTol=0);
            testCase.verifyEqual(schedule, [0; 2; 2; 0; 0; 0; 0; 0], AbsTol=0);
        end

        function testKappaValues(testCase)
            values = rstar.utils.kappaValues([0.5, 1.5], [0; 1; 2; 1]);

            testCase.verifyEqual(values, [1; 0.5; 1.5; 0.5], AbsTol=0);
        end

        function testObservationNoise(testCase)
            noise = rstar.utils.observationNoise([0.5, 1.5], 2, 3, ...
                [0; 1; 2]);

            testCase.verifyEqual(noise{1}, diag([2, 3]), AbsTol=0);
            testCase.verifyEqual(noise{2}, diag([1, 1.5]), AbsTol=0);
            testCase.verifyEqual(noise{3}, diag([3, 4.5]), AbsTol=0);
        end
    end
end
