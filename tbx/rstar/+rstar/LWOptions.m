classdef LWOptions < rstar.Options
    %LWOptions Settings for the original Laubach-Williams specification.
    %
    %   Copyright 2026 The MathWorks, Inc.

    properties
        ISCurveUpperBound (1,1) double {mustBeFinite, mustBeReal} = -0.0025
        PhillipsCurveLowerBound (1,1) double {mustBeFinite, mustBeReal} = 0.025
    end

    methods
        function obj = LWOptions(nvArgs)
            %LWOptions Construct settings for the original LW specification.

            arguments
                nvArgs.?rstar.LWOptions
            end

            obj.ModelName = "LW";
            names = fieldnames(nvArgs);
            for index = 1:numel(names)
                obj.(names{index}) = nvArgs.(names{index});
            end
        end
    end
end
