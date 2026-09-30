function noise = observationNoise(parameters, outputGapStandardDeviation, ...
        inflationStandardDeviation, kappaSchedule)
%observationNoise Construct period-specific measurement-noise factors.
%
%   Copyright 2026 The MathWorks, Inc.

arguments
    parameters {mustBeNumeric, mustBeFinite, mustBeReal}
    outputGapStandardDeviation (1,1) double {mustBeFinite, mustBeReal}
    inflationStandardDeviation (1,1) double {mustBeFinite, mustBeReal}
    kappaSchedule (:,1) double {mustBeInteger, mustBeReal, mustBeNonnegative}
end

kappa = rstar.utils.kappaValues(parameters, kappaSchedule);
noise = cell(numel(kappaSchedule), 1);
for period = 1:numel(kappaSchedule)
    noise{period} = kappa(period) * ...
        diag([outputGapStandardDeviation, inflationStandardDeviation]);
end
end
