function options = rstarOptions(modelName, varargin)
%rstarOptions Construct settings for a named published r-star model.
%
%   options = rstarOptions(modelName) returns default settings.
%   options = rstarOptions(modelName, Name=Value) applies model-specific
%   settings. Supported model names are "LW", "LW2023", "HLW", and "HLW2023".
%
%   Copyright 2026 The MathWorks, Inc.

    arguments
        modelName (1,1) string {mustBeMember(modelName, ["LW", "LW2023", "HLW", "HLW2023"])}
    end
    
    arguments (Repeating)
        varargin
    end

    switch upper(modelName)
        case "LW"
            options = rstar.LWOptions(varargin{:});
        case "LW2023"
            options = rstar.LW2023Options(varargin{:});
        case "HLW"
            options = rstar.HLWOptions(varargin{:});
        case "HLW2023"
            options = rstar.HLW2023Config(varargin{:});
    end
end
