% Copyright 2026 The MathWorks, Inc.

classdef PrepareQuarterlyDataTest < matlab.unittest.TestCase
    %PrepareQuarterlyDataTest Unit tests for shared 2023 sample preparation.

    methods (Test)
        function testInfersSampleBounds(testCase)
            data = quarterlyData("date", 2018, 24);
            options = rstar.LW2023Options();

            [actual, actualOptions] = rstar.utils.prepareQuarterlyData(data, options, 8);

            testCase.verifyEqual(actualOptions.SampleStart, datetime(2020, 1, 1));
            testCase.verifyEqual(actualOptions.SampleEnd, datetime(2023, 10, 1));
            testCase.verifyEqual(actual.date(1), datetime(2018, 1, 1));
            testCase.verifyEqual(actual.date(end), datetime(2023, 10, 1));
        end

        function testCanonicalizesUppercaseDate(testCase)
            data = quarterlyData("Date", 2018, 24);
            options = rstar.LW2023Options(SampleStart=datetime(2020, 1, 1));

            actual = rstar.utils.prepareQuarterlyData(data, options, 8);

            testCase.verifyTrue(ismember("date", string(actual.Properties.VariableNames)));
            testCase.verifyFalse(ismember("Date", string(actual.Properties.VariableNames)));
            testCase.verifyEqual(actual.date(1), datetime(2018, 1, 1));
        end

        function testCanonicalizesTimeColumn(testCase)
            data = quarterlyData("Time", 2018, 24);
            options = rstar.LW2023Options(SampleStart=datetime(2020, 1, 1));

            actual = rstar.utils.prepareQuarterlyData(data, options, 8);

            testCase.verifyTrue(ismember("date", string(actual.Properties.VariableNames)));
            testCase.verifyFalse(ismember("Time", string(actual.Properties.VariableNames)));
            testCase.verifyEqual(actual.date(1), datetime(2018, 1, 1));
        end

        function testUsesTimetableRowTimes(testCase)
            dates = datetime(2018, 1, 1) + calquarters((0:23)');
            data = timetable(dates, (1:24)', VariableNames="value");
            options = rstar.HLW2023Config(SampleStart=datetime(2020, 1, 1));

            actual = rstar.utils.prepareQuarterlyData(data, options, 8);

            testCase.verifyClass(actual, "table");
            testCase.verifyTrue(ismember("date", string(actual.Properties.VariableNames)));
            testCase.verifyEqual(actual.date(1), datetime(2018, 1, 1));
        end

        function testSupportsFourQuarterPresample(testCase)
            data = quarterlyData("date", 2020, 13);
            options = rstar.HLW2023Config(SampleStart=datetime(2021, 1, 1));

            actual = rstar.utils.prepareQuarterlyData(data, options, 4);

            testCase.verifyEqual(actual.date(1), datetime(2020, 1, 1));
            testCase.verifyEqual(actual.date(5), datetime(2021, 1, 1));
        end

        function testAppliesExplicitSampleEnd(testCase)
            data = quarterlyData("date", 2018, 24);
            options = rstar.HLW2023Config(SampleStart=datetime(2020, 1, 1), ...
                SampleEnd=datetime(2022, 1, 1));

            actual = rstar.utils.prepareQuarterlyData(data, options, 8);

            testCase.verifyEqual(actual.date(end), datetime(2022, 1, 1));
            testCase.verifySize(actual, [17, 2]);
        end

        function testRejectsIrregularDates(testCase)
            data = table([datetime(2018, 1, 1); datetime(2018, 4, 1); ...
                datetime(2018, 10, 1)], [1; 2; 3], ...
                VariableNames=["date", "value"]);
            options = rstar.HLW2023Config(SampleStart=datetime(2020, 1, 1));

            testCase.verifyError(@() rstar.utils.prepareQuarterlyData(data, options, 8), ...
                "rstar:utils:prepareQuarterlyData:IrregularDates");
        end

        function testRejectsMissingDateVariable(testCase)
            data = table((1:20)', VariableNames="value");
            options = rstar.LW2023Options(SampleStart=datetime(2020, 1, 1));

            testCase.verifyError(@() rstar.utils.prepareQuarterlyData(data, options, 8), ...
                "rstar:utils:prepareQuarterlyData:MissingDate");
        end
    end
end

function data = quarterlyData(dateName, startYear, numberOfPeriods)
dates = datetime(startYear, 1, 1) + calquarters((0:numberOfPeriods-1)');
data = table(dates, (1:numberOfPeriods)', VariableNames=[dateName, "value"]);
end
