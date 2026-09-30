% Copyright 2026 The MathWorks, Inc.

function files = setupPublishedData(options)
%setupPublishedData Download the current published workbooks for tests.
%
%   FILES = setupPublishedData returns local paths to the current
%   Laubach-Williams and Holston-Laubach-Williams workbooks. The files are
%   cached outside the repository and downloaded only when absent.

arguments
    options.CacheFolder (1,1) string = fullfile(tempdir, "rstar-test-data")
end

if ~isfolder(options.CacheFolder)
    mkdir(options.CacheFolder);
end

files = struct;
files.LW = downloadWorkbook(options.CacheFolder, ...
    "Laubach_Williams_current_estimates.xlsx", ...
    "https://www.newyorkfed.org/medialibrary/media/research/" + ...
    "economists/williams/data/Laubach_Williams_current_estimates.xlsx");
files.HLW = downloadWorkbook(options.CacheFolder, ...
    "Holston_Laubach_Williams_current_estimates.xlsx", ...
    "https://www.newyorkfed.org/medialibrary/media/research/" + ...
    "economists/williams/data/Holston_Laubach_Williams_current_estimates.xlsx");
end

function file = downloadWorkbook(cacheFolder, fileName, url)
file = fullfile(cacheFolder, fileName);
if isfile(file)
    return
end

try
    websave(file, url);
catch exception
    error("rstar:test:PublishedDataDownloadFailed", ...
        "Could not download %s. Check network access and retry.\n%s", ...
        fileName, exception.message);
end
end
