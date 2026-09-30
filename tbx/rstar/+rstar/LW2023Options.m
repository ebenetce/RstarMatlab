classdef LW2023Options < rstar.CovidAdjustedOptions
    %LW2023Options Settings for the current Laubach-Williams specification.
    %
    %   Copyright 2026 The MathWorks, Inc.

    methods
        function obj = LW2023Options(nvArgs)
            %LW2023Options Construct current LW settings.

            arguments
                nvArgs.?rstar.CovidAdjustedOptions
            end

            obj = obj.applyOptions(nvArgs, "LW2023");
        end
    end
end
