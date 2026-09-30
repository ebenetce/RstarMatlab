classdef HLWOptions < rstar.Options
    %HLWOptions Settings for the original HLW specification.
    %
    %   Copyright 2026 The MathWorks, Inc.
    methods
        function obj = HLWOptions(nvArgs)
            %HLWOptions Construct settings for the original HLW specification.

            arguments
                nvArgs.?rstar.HLWOptions
            end

            names = fieldnames(nvArgs);
            for index = 1:numel(names)
                obj.(names{index}) = nvArgs.(names{index});
            end
            obj.ModelName = "HLW";
        end
    end
end
