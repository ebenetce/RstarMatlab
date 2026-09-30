% Copyright 2026 The MathWorks, Inc.

%% Reproduce the current U.S. Laubach-Williams estimates
%
% To rebuild the U.S. HLW-2023 input series from FRED, open
% <a href="matlab:open('RecreateHLW2023USInputFromFRED.m')">RecreateHLW2023USInputFromFRED.m</a>.

lwUrl = "https://www.newyorkfed.org/medialibrary/media/research/economists/williams/data/Laubach_Williams_current_estimates.xlsx";
lwData = readtable(lwUrl, Sheet="input data", VariableNamingRule="preserve");
mdl = rstar("LW2023", rstarOptions("LW2023", Verbose=false));
lwResults = mdl.estimate(lwData);
lwDates = lwData.Date(9:end);

figure(Color="white")
hold on
plot(lwDates, lwResults.stage3.rstarFiltered, LineWidth=2, ...
    DisplayName="Natural rate")
plot(lwDates, lwResults.stage3.trendFiltered, LineWidth=2, ...
    DisplayName="Trend growth")
title("Current U.S. Laubach-Williams estimates")
xlabel("Quarter")
ylabel("Percent")
xlim([datetime(1985,1,1), lwDates(end)])
ylim([0, 4])
grid on
box on
legend(Location="southwest")

%% Reproduce the current U.S. Holston-Laubach-Williams estimates

hlwUrl = "https://www.newyorkfed.org/medialibrary/media/research/economists/williams/data/Holston_Laubach_Williams_current_estimates.xlsx";
hlwData = readtable(hlwUrl, Sheet="US input data", VariableNamingRule="preserve");

optimizer = rstar.utils.maximumLikelihoodOptions( MaxIterations=20000, MaxFunctionEvaluations=50000);

hlwOptions = rstarOptions("HLW2023", OptimizationOptions=optimizer);
mdl = rstar("HLW2023", hlwOptions);
hlwResults = mdl.estimate(hlwData);
hlwDates   = hlwData.date(5:end);

figure(Color="white")
hold on
plot(hlwDates, hlwResults.stage3.rstarFiltered, LineWidth=2, ...
    DisplayName="Natural rate")
plot(hlwDates, hlwResults.stage3.trendFiltered, LineWidth=2, ...
    DisplayName="Trend growth")
title("Current U.S. Holston-Laubach-Williams estimates")
xlabel("Quarter")
ylabel("Percent")
xlim([datetime(1985,1,1), hlwDates(end)])
ylim([0, 4])
grid on
box on
legend(Location="southwest")

%% Other economies

% Canada
caData = readtable(hlwUrl, Sheet="CA input data", VariableNamingRule="preserve");
mdl.Verbose = false;
caResults = mdl.estimate(caData);

% Euro area
eaData = readtable(hlwUrl, Sheet="EA input data", VariableNamingRule="preserve");

kappaInputs = rstar.CovidAdjustedOptions.defaultKappaInputs();
kappaInputs(end+1, :) = {"kappa2023", datetime(2023,1,1), datetime(2023,10,1), 1, 1, Inf};
optimizer = rstar.utils.maximumLikelihoodOptions( MaxIterations=20000, MaxFunctionEvaluations=50000);
options = rstarOptions("HLW2023", KappaInputs=kappaInputs, OptimizationOptions=optimizer, Verbose = false);

eaResults = rstar("HLW2023", options).estimate(eaData);

US = timetable(hlwResults.stage3.rstarFiltered, ...
    hlwResults.stage3.trendFiltered, hlwResults.stage3.outputGapFiltered, RowTimes = hlwDates, VariableNames = ["Natural Rate of Interest", "Trend Growth", "Output Gap"]);

CA = timetable(caResults.stage3.rstarFiltered, ...
    caResults.stage3.trendFiltered, caResults.stage3.outputGapFiltered, RowTimes = hlwDates, VariableNames = ["Natural Rate of Interest", "Trend Growth", "Output Gap"]);

EA = timetable(eaResults.stage3.rstarFiltered, ...
    eaResults.stage3.trendFiltered, eaResults.stage3.outputGapFiltered, RowTimes = eaData.date(5:end), VariableNames = ["Natural Rate of Interest", "Trend Growth", "Output Gap"]);

figure('Color','w')
ax = stackedplot(US, CA, EA, LegendLabels = ["United States", "Canada", "Euro Area"]);
grid on
ax.AxesProperties(1).YLimits = [0,8];
ax.AxesProperties(2).YLimits = [0,6];
ax.AxesProperties(3).YLimits = [-10,10];
