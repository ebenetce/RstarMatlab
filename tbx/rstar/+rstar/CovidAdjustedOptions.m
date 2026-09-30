classdef (Abstract) CovidAdjustedOptions < rstar.Options
    %CovidAdjustedOptions Shared settings for COVID-adjusted r-star models.
    %
    %   Copyright 2026 The MathWorks, Inc.

    properties
        SampleStart (1,1) datetime = NaT %datetime(1961, 1, 1)
        SampleEnd (1,1) datetime = NaT
        ISCurveUpperBound (1,1) double {mustBeFinite, mustBeReal} = -0.0025
        PhillipsCurveLowerBound (1,1) double {mustBeFinite, mustBeReal} = 0.025
        EstimatePhi (1,1) logical = true
        FixedPhi (1,1) double {mustBeReal} = NaN
        UseKappa (1,1) logical = true
        KappaInputs table = rstar.CovidAdjustedOptions.defaultKappaInputs()
        RunStandardErrors (1,1) logical = false
    end

    methods (Access = protected)
        function obj = applyOptions(obj, nvArgs, modelName)
            propertyNames = fieldnames(nvArgs);
            for index = 1:numel(propertyNames)
                obj.(propertyNames{index}) = nvArgs.(propertyNames{index});
            end
            obj.ModelName = modelName;

            if ~obj.EstimatePhi && isnan(obj.FixedPhi)
                error("rstar:CovidAdjustedOptions:MissingFixedPhi", ...
                    "Set FixedPhi when EstimatePhi is false.");
            end
            if obj.EstimatePhi && ~isnan(obj.FixedPhi)
                error("rstar:CovidAdjustedOptions:ConflictingPhiSettings", ...
                    "Set either EstimatePhi to true or provide FixedPhi, not both.");
            end
        end
    end

    methods (Static)
        function kappaInputs = defaultKappaInputs()
            %defaultKappaInputs Return the U.S. kappa schedule.

            kappaInputs = table( ...
                ["kappa2020Q2-Q4"; "kappa2021"; "kappa2022"], ...
                datetime([2020; 2021; 2022], [4; 1; 1], 1), ...
                datetime([2020; 2021; 2022], [10; 10; 10], 1), ...
                [1; 1; 1], [1; 1; 1], [Inf; Inf; Inf], ...
                VariableNames=["Name", "StartDate", "EndDate", "InitialValue", ...
                "LowerBound", "UpperBound"]);
        end
    end
end
