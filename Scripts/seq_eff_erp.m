% analyse sequential dependencies in fly ERPs

close all;
clear;

%% load peak finder
toolPath = 'D:\group_swinderen\Matthew\Scripts\toolboxes';
addpath([toolPath filesep 'basefindpeaks']);

%% load auxiliary functions

addpath('D:\group_swinderen\Dinis\Scripts\Global functions\');
addpath('D:\group_swinderen\Dinis\Scripts\Indexes and legends\');

%% load data

dataPath = "D:\group_swinderen\Dinis\Output\201021\LFP\Analyzed_TagTrials_block5\201021_chunk_0.mat";
load(dataPath);

% resampling frequency
resampleFreq = EEG.srate;

%time vector
times = EEG.times;

%% LFP
lfpData = EEG.LFP1.data;

%% find peaks in photodiode data
photData = EEG.PHOT.data; photData(2,:) = -photData(2,:); %Light bar
[PKS_PHOT1,LOCS_PHOT1] = findpeaksbase( photData(1,:) , 'MinPeakHeight' , 1.5 , 'MinPeakDistance' , 0.5*resampleFreq ); %Light bar
[PKS_PHOT2,LOCS_PHOT2] = findpeaksbase( photData(2,:) , 'MinPeakHeight' , 0.0005 , 'MinPeakDistance' , 0.5*resampleFreq ); %Light bar

% photData = EEG.PHOT.data; photData(1,:) = -photData(1,:); % Dark bar
% [PKS_PHOT1,LOCS_PHOT1] = findpeaksbase( photData(1,:) , 'MinPeakHeight' , 0.0001 , 'MinPeakDistance' , 0.5*resampleFreq ); %Dark bar
% [PKS_PHOT2,LOCS_PHOT2] = findpeaksbase( photData(2,:) , 'MinPeakHeight' , 0.0005 , 'MinPeakDistance' , 0.5*resampleFreq ); %Dark bar

%remove outliers (from visual inspection)
LOCS_PHOT1 = LOCS_PHOT1(PKS_PHOT1 < 3e-4); PKS_PHOT1 = PKS_PHOT1(PKS_PHOT1 < 3e-4);
LOCS_PHOT2 = LOCS_PHOT2(PKS_PHOT2 < 1.6e-3); PKS_PHOT2 = PKS_PHOT2(PKS_PHOT2 < 1.6e-3);

%% infer random sequence (0 - left; 1 - right)
randomSequence = zeros(1,length(photData));
randomSequence(LOCS_PHOT1) = 2; randomSequence(LOCS_PHOT2) = 1;
randomSequence = randomSequence(logical(randomSequence));
randomSequence = randomSequence-1;

%% fuse LOCS (I figured this was quicker than concatenating and sorting)
LOCS = zeros(1,length(photData));
LOCS(LOCS_PHOT1) = LOCS_PHOT1; LOCS(LOCS_PHOT2) = LOCS_PHOT2;
LOCS = LOCS(logical(LOCS));

%% time window
time_before_peak = 0.05; time_after_peak = 0.8;
window = floor([-time_before_peak*resampleFreq,time_after_peak*resampleFreq]);

%% analyse sequential dependencies

n_back = 5; n_seq = 2^n_back; sequenceLength = length(randomSequence);

ERPS = zeros(length(window(1):window(2)), n_seq, length(n_back:sequenceLength));

for n = n_back:sequenceLength
    
    % decimal value of binary sequence of length n_back
    seq = bin2dec(num2str(randomSequence(n-(n_back-1):n)))+1;
    
    % stack ERPs along third dimension
    ERPS(:, seq, n+1-n_back) = lfpData(LOCS(n) + window(1) : LOCS(n) + window(2));

end

%% remove outliers from ERPs (some have colossal peaks)

outlier_bounds = [-.02 .025];

max_erps = sum(max(ERPS, [], 1), 2); min_erps = sum(min(ERPS, [], 1), 2);

ERPS = ERPS(:,:, min_erps > outlier_bounds(1) & max_erps < outlier_bounds(2));
%% 

ERPS(ERPS == 0) = nan;

meanERPS = mean(ERPS, 3, 'omitnan');

%group sequences 2 by 2 (00001 is the same as 11110 and so on)
meanERPS = meanERPS + fliplr(meanERPS); 
meanERPS(:,n_seq/2 + 1:end) = [];
meanERPS = meanERPS/2;

erp_seq_eff = max(meanERPS, [], 1) - min(meanERPS, [], 1);

% correct for baseline
% erp_seq_eff = erp_seq_eff - meanERPS(:,15);

create_seq_eff_plot(-erp_seq_eff(seq_eff_order(n_back)).',[]);