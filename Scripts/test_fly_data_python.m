clear
close all

PY_DATA = readtable('..\Python Data\ClosedLoop-Dinis_Oct 15_Fly_1_Trial_1.txt');

% epoch_times = PY_DATA.EpochTime;
epoch_times = PY_DATA.CurrTim;
stage = PY_DATA.Stage;

stage(stage ~= 1) = 0;

start_stop = find(diff(stage));
times_stage1 = epoch_times(start_stop);

periods = length(start_stop)/2;

for i = 2:2:length(start_stop)
    periods(i/2) = times_stage1(i)-times_stage1(i-1);
end

periods = abs(periods);

histogram(periods);

% histogram(diff(PY_DATA.EpochTime));