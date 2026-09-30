classdef HLW2023Config < rstar.CovidAdjustedOptions
    %HLW2023Config Settings for the COVID-adjusted HLW 2023 specification.
    %
    %   Copyright 2026 The MathWorks, Inc.

    methods
        function obj = HLW2023Config(nvArgs)
            %HLW2023Config Construct configuration with name-value settings.

            arguments
                nvArgs.?rstar.CovidAdjustedOptions
            end

            obj = obj.applyOptions(nvArgs, "HLW2023");
        end
    end

    methods (Static)
        function kappaInputs = defaultKappaInputs()
            %defaultKappaInputs Return the shared annual-kappa specification.

            kappaInputs = rstar.CovidAdjustedOptions.defaultKappaInputs();
        end
    end
end
