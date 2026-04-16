clear
close all

load('..\Output\151021\LFP\Analyzed_TagTrials_block4\151021_chunk_0');

%epoch_times = EEG.ARAA.data(2,:);
epoch_times = EEG.times;
stage = EEG.ARAA.data(3,:);

stage(stage ~= 1) = 0;

start_stop = find(diff(stage));
times_stage1 = epoch_times(start_stop);

periods = length(start_stop)/2;

for i = 2:2:length(start_stop)
    periods(i/2) = times_stage1(i)-times_stage1(i-1);
end

periods = abs(periods);

histogram(periods);