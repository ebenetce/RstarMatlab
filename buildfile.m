% Copyright 2026 The MathWorks, Inc.

function plan = buildfile
%buildfile Define code-check, test, and toolbox-package build tasks.
import matlab.buildtool.tasks.*

plan = buildplan(localfunctions);
plan.DefaultTasks = "package";
plan('check') = CodeIssuesTask(SourceFiles = 'tbx/rstar',WarningThreshold = 0);
plan('test') = TestTask('tests', SourceFiles = 'tbx/rstar', ...
    TestResults = 'public/results.html', ...
    CodeCoverageResults=["public/coverage.xml", "public/coverage.html"]);
plan("package").Dependencies = ["check", "test", "doc"];
end

function packageTask(context)
%package Build a toolbox package containing tbx exactly as currently laid out.

v = ver('rstar').Version;

packageFolder = fullfile(context.Plan.RootFolder, "tbx");
releaseFolder = fullfile(context.Plan.RootFolder, "release");
outputFile = fullfile(releaseFolder, "Rstar.mltbx");

if ~isfolder(releaseFolder)
    mkdir(releaseFolder);
end

options = matlab.addons.toolbox.ToolboxOptions( ...
    packageFolder, "5d1f1c81-4b1a-4c9b-9b17-4b436f75e8b6");
options.AuthorEmail = "ebenetce@mathworks.com";
options.AuthorName = "Eduard Benet Cerda";
options.AuthorCompany = "MathWorks";
options.ToolboxName = "Rstar";
options.PackageName = "rstar";
options.ToolboxVersion = v;
options.Summary = "Natural-rate estimators for LW and HLW models.";
options.OutputFile = outputFile;
options.ProductDependencies = "Econometrics Toolbox";
options.ToolboxGettingStartedGuide = fullfile(context.Plan.RootFolder, 'tbx', 'doc', 'mfiles', 'GettingStarted.m');
matlab.addons.toolbox.packageToolbox(options);
end

function docTask(~)
%doc Build and index the toolbox HTML documentation.

if isempty(ver("docmaker"))
    websave("MATLAB_DocMaker.mltbx", ...
        "https://github.com/mathworks/docmaker/releases/latest/download/MATLAB_DocMaker.mltbx");
    cleanup = onCleanup(@() delete("MATLAB_DocMaker.mltbx"));
    matlab.addons.install("MATLAB_DocMaker.mltbx", true);
end

documentationFolder = fullfile(currentProject().RootFolder, "tbx", "doc");
resourcesFolder = fullfile(documentationFolder, "resources");
if isfolder(resourcesFolder)
    resourceFiles = dir(fullfile(resourcesFolder, "*"));
    resourceFiles = resourceFiles(~[resourceFiles.isdir]);
    if ~isempty(resourceFiles)
        resourcePaths = fullfile({resourceFiles.folder}, {resourceFiles.name});
        resourcePermissions = filePermissions(resourcePaths);
        setPermissions(resourcePermissions, "Writable", true);
    end
end
docdelete(documentationFolder)

markdownFiles = fullfile(documentationFolder, "**", "*.md");
htmlFiles = docconvert(markdownFiles);
docrun(htmlFiles)
docindex(documentationFolder)
end

function files = toolboxFiles(packageFolder)
%toolboxFiles Return all files below the package folder.

fileInfo = dir(fullfile(packageFolder, "**", "*"));
fileInfo = fileInfo(~[fileInfo.isdir]);
files = string(fullfile({fileInfo.folder}, {fileInfo.name}))';
end
