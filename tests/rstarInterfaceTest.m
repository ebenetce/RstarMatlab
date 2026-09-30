% Copyright 2026 The MathWorks, Inc.

classdef rstarInterfaceTest < matlab.unittest.TestCase
    %rstarInterfaceTest Tests for the public model and options factories.

    properties (TestParameter)
        modelName = {"LW", "LW2023", "HLW", "HLW2023"}
    end

    methods (Test, TestTags = {'Unit'})
        function testOptionsFactoryReturnsModelSpecificClasses(testCase)
            lw = rstarOptions("LW");
            lw2023 = rstarOptions("LW2023");
            hlw = rstarOptions("HLW");
            hlw2023 = rstarOptions("HLW2023");

            testCase.verifyClass(lw, "rstar.LWOptions");
            testCase.verifyClass(lw2023, "rstar.LW2023Options");
            testCase.verifyClass(hlw, "rstar.HLWOptions");
            testCase.verifyClass(hlw2023, "rstar.HLW2023Config");
        end

        function testFactoryReturnsHLWModel(testCase)
            model = rstar("HLW");

            testCase.verifyClass(model, "rstar.HLWModel");
            testCase.verifyEqual(model.Name, "HLW");
        end

        function testFactoryReturnsHLW2023Model(testCase)
            model = rstar("HLW2023");

            testCase.verifyClass(model, "rstar.HLW2023Model");
            testCase.verifyEqual(model.Name, "HLW2023");
        end

        function testFactoryRejectsOptionsFromAnotherModel(testCase)
            options = rstarOptions("HLW2023");

            testCase.verifyError(@() rstar("HLW", options), ...
                "rstar:Options:IncompatibleModel");
        end

        function testAllModelsAcceptOptimizationOptions(testCase, modelName)
            optimizationOptions = rstar.utils.maximumLikelihoodOptions( ...
                MaxIterations=10000);

            options = rstarOptions(modelName, ...
                OptimizationOptions=optimizationOptions);

            testCase.verifyEqual(options.OptimizationOptions.MaxIterations, 10000);
        end

        function testLWValidatesRequiredInputVariables(testCase)
            model = rstar("LW");

            testCase.verifyError(@() model.estimate(table), ...
                "rstar:LWModel:MissingVariables");
        end
    end
end
