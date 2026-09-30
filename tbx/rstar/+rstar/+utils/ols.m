function [coefficients, residuals, standardDeviation] = ols(design, response)
%ols Fit an ordinary least-squares regression.
%
%   [coefficients, residuals, standardDeviation] = rstar.utils.ols(design,
%   response) regresses the column vector response on the columns of
%   design. standardDeviation is the residual standard deviation.
%
%   Copyright 2026 The MathWorks, Inc.

arguments
    design {mustBeNumeric, mustBeReal}
    response {mustBeNumeric, mustBeReal}
end

if size(design,1) ~= size(response,1)
    error("rstar:utils:ols:IncompatibleSize", ...
        "Design and response must have the same number of rows.");
end
if size(response,2) ~= 1
    error("rstar:utils:ols:InvalidResponse", ...
        "Response must be a column vector.");
end

coefficients = design \ response;
residuals = response - design * coefficients;
standardDeviation = sqrt(sum(residuals.^2) / ...
    (size(design,1) - size(design,2)));
end
