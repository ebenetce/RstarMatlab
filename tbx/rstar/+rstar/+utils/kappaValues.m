function values = kappaValues(parameters, schedule)
%kappaValues Expand a kappa parameter schedule to period-specific values.
%
%   Copyright 2026 The MathWorks, Inc.

arguments
    parameters {mustBeNumeric, mustBeFinite, mustBeReal}
    schedule (:,1) double {mustBeInteger, mustBeReal, mustBeNonnegative}
end

values = ones(numel(schedule), 1);
active = schedule ~= 0;
values(active) = parameters(schedule(active));
end
