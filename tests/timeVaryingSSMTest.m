% Copyright 2026 The MathWorks, Inc.

classdef timeVaryingSSMTest < matlab.unittest.TestCase
    %timeVaryingSSMTest Verify toolbox support required by HLW-2023.

    methods (Test)
        function testParamMapSupportsTimeVaryingObservationNoise(testCase)
            model = ssm(@timeVaryingObservationMap);
            observations = [1; 1.2; 0.9];

            [estimatedModel, parameter] = estimate( ...
                model, observations, 0.5, Display="off");

            testCase.verifyClass(estimatedModel.D, "cell");
            testCase.verifySize(estimatedModel.D, [3, 1]);
            testCase.verifyTrue(isfinite(parameter));
        end
    end
end

function [A, B, C, D, Mean0, Cov0, StateType] = timeVaryingObservationMap(parameter)
    A = 1;
    B = 0.1;
    C = 1;
    D = {parameter; 2 * parameter; 3 * parameter};
    Mean0 = 0;
    Cov0 = 1;
    StateType = 0;
end
