% analyse sequential dependencies in fly ERPs
close all;
clear;

%% load peak finder (Matt's code)
toolPath = 'D:\group_swinderen\Matthew\Scripts\toolboxes';
addpath([toolPath filesep 'basefindpeaks']);

%% load auxiliary functions (Dinis' code)
addpath('D:\group_swinderen\Dinis\Scripts\Global functions\');
addpath('D:\group_swinderen\Dinis\Scripts\Indexes and legends\');

%% load data
dataPath = 'D:\group_swinderen\Dinis\Output\191121\LFP';

% get blocks for this date/fly
blocks = extractfield(dir(dataPath), 'name'); blocks = blocks(3:end);

% sort blocks
blockNums = regexp(blocks,'[0-9]*','match');
[blockNums,ind_blocks] = sort(str2double([blockNums{:}]));
blocks = blocks(ind_blocks);

%% choose blocks to use
whichBlocks = [3 4];

% get index of chosen blocks in "blocks"
[~,loc] = ismember(whichBlocks, blockNums);

blocks = blocks(loc);

n_blocks = length(blocks);

%% time window
time_before_peak = .1*ones(1,n_blocks);
time_after_peak =  .7*ones(1,n_blocks);

%% inter-stimulus interval (in seconds)
ISI = 0.8*ones(1,n_blocks);

%% HACK!!! 
%TODO: add tag to experiment script stating whether it is B on D or D on B
%light_on_dark = 1 means a bright bar over a dark background was used
light_on_dark = [1 0];

%% load data of chosen blocks/experiments into cell arrays
LFP = {}; PHOT = {}; times = {}; resampleFreq = {}; rawPHOT = {};

date = '191121';

for block = 1:n_blocks

    load([dataPath '/' blocks{block} '/' date '_chunk_0']);

    times{block} = EEG.times; %#ok<*SAGROW>
    LFP{block} = EEG.LFP1.data.'; 
    PHOT{block} = EEG.PHOT.data.';
    rawPHOT{block} = EEG.PHOT.data;
    resampleFreq{block} = EEG.srate;

    % correct for the fact that the left photodiode is inverted
    % such that peaks are always upward for peak detection
    if light_on_dark(block)
        PHOT{block}(:,2) = -PHOT{block}(:,2);
        rawPHOT{block}(:,2) = -rawPHOT{block}(:,2);
    else
        PHOT{block}(:,1) = -PHOT{block}(:,1); 
        rawPHOT{block}(:,1) = -rawPHOT{block}(:,1);
    end

    % nuke photodiode data beyond some ridiculous sd
    % main point here is to make outlier and peak detection calculations universal
    ridiculous_sd = 5;
    PHOT{block} = PHOT{block}.*(abs(normalize(PHOT{block},2)) < ridiculous_sd);

    % butterworth level 4 filter (low pass) for both LFP and PHOT
    [b_f,a_f] = butter(6,50/resampleFreq{block}*2);
    LFP{block} = filter(b_f,a_f,LFP{block}).';
    
    [b_f,a_f] = butter(9,50/resampleFreq{block}*2);
    PHOT{block} = filter(b_f,a_f,PHOT{block}).';

end

%% add data to structure
FLY = struct;
    
for block = 1:n_blocks

    FLY.block(block).LFP = LFP{block};
    FLY.block(block).PHOT = PHOT{block};
    FLY.block(block).rawPHOT = rawPHOT{block};
    FLY.block(block).times = times{block};
    FLY.block(block).resampleFreq = resampleFreq{block};
    FLY.block(block).time_before_peak = time_before_peak(block);
    FLY.block(block).time_after_peak = time_after_peak(block);
    FLY.block(block).ISI = ISI(block);

end

%% analyse data per fly and whether experiment is lit or unlit
    
lit_dark = {'DARK','LIT'};

[erp_seq_eff,semSeq,nERPs,meanERPS, meanPHOT] = processFly(FLY, [1 2], light_on_dark);

FLY.(lit_dark{light_on_dark+1}).erp_seq_eff = erp_seq_eff;
FLY.(lit_dark{light_on_dark+1}).semSeq = semSeq;
FLY.(lit_dark{light_on_dark+1}).nERPs = nERPs;
FLY.(lit_dark{light_on_dark+1}).meanERPS = meanERPS;
FLY.(lit_dark{light_on_dark+1}).meanPHOT = meanPHOT;

%% plot average sequential dependencies for all selected flies together
    
lit_dark = {'DARK','LIT'};

figure;
create_seq_eff_plot(-FLY.(lit_dark{light_on_dark+1}).erp_seq_eff.',[],'errors',FLY.(lit_dark{light_on_dark+1}).semSeq.');
saveas(gcf,['fly_' lit_dark{light_on_dark+1} '.png']);

% seq_eff(:,fly) = FLIES(chosenFlies(fly)).(lit_dark{lit+1}).erp_seq_eff.';
% n(fly) = sum(FLIES(chosenFlies(fly)).(lit_dark{lit+1}).nERPs);
% seq_eff(:,fly) = seq_eff(:,fly)*n(fly);

% figure;
% create_seq_eff_plot(sum(seq_eff,2)/sum(n),[]);
% saveas(gcf,['all_flies_' lit_dark{lit+1} '.png']);

%% plot mean ERP for lit vs unlit for each fly
   
figure;
hold on
% plot(normalize(sum(FLY.(lit_dark{light_on_dark+1}).meanERPS,2)/16));
plot((sum(FLY.(lit_dark{light_on_dark+1}).meanPHOT,2)/16));
plot((sum(FLY.(lit_dark{light_on_dark}).meanPHOT,2)/16),'r.');
% if light_on_dark
%     legend('ERP LIT','PHOT LIT');
% end
% saveas(gcf,['meanERP_LIT_' lit_dark{light_on_dark+1} '.png']);