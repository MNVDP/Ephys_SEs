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
dataPath = 'D:\group_swinderen\Dinis\Output';

dates = extractfield(dir(dataPath), 'name'); dates = dates(3:end); % get rid of . and ..

% sort dates
[~,ind_dates] = sort(datenum(dates,'ddmmyy'));
dates = dates(ind_dates);

%% choose flies and experiments
whichFly =      [1 1 2 2 3 3 3 4 4 5 5 6 6 6 7 7 8 8 8 9 9 10 10 10 11 11 11 12 12 13 13];
flySet = unique(whichFly);

n_blocks = length(whichFly);

chosenFlies = [13];
% chosenFlies = flySet; % choose all flies
chosenOnes = ismember(whichFly, chosenFlies);

%% individual time windows for each fly
% the reason for setting these individually, for now, is because different
% flies have different ERPs; this will have to change in the future
time_before_peak = .1*ones(1,n_blocks);
time_after_peak =  .7*ones(1,n_blocks);

%% HACK!!! 
%TODO: add tag to experiment script stating whether it is B on D or D on B
%light_on_dark = 1 means a bright bar over a dark background was used
light_on_dark = [1 0 1 0 1 0 1 1 0 1 0 1 0 1 1 0 1 0 1 1 0 0 1 0 0 1 0 1 0 1 0];
% chosenOnes = 1-light_on_dark;

%% inter-stimulus interval (in seconds)
ISI = .8*ones(1,n_blocks);

%% load data of chosen experiments into cell arrays
LFP = {}; PHOT = {}; times = {}; resampleFreq = {}; rawPHOT = {};

exp = 1;

for d = 1:length(dates)
    
    currentDateDirectory = ['../Output/' dates{d} '/LFP'];

    % get blocks for current date
    blocks = extractfield(dir(currentDateDirectory), 'name'); blocks = blocks(3:end);
    
    % sort blocks
    blockNums = regexp(blocks,'[0-9]*','match');
    [~,ind_blocks] = sort(str2double([blockNums{:}]));
    blocks = blocks(ind_blocks);
    
    for b = 1:length(blocks)
        
        if chosenOnes(exp)

            load([currentDateDirectory '/' blocks{b} '/' dates{d} '_chunk_0']);

            times{exp} = EEG.times; %#ok<*SAGROW>
            LFP{exp} = EEG.LFP1.data.'; 
            PHOT{exp} = EEG.PHOT.data.';
            rawPHOT{exp} = EEG.PHOT.data;
            resampleFreq{exp} = EEG.srate;
            
            % correct for the fact that the left photodiode is inverted
            % such that peaks are always upward for peak detection
            if light_on_dark(exp)
                PHOT{exp}(:,2) = -PHOT{exp}(:,2);
                rawPHOT{exp}(:,2) = -rawPHOT{exp}(:,2);
            else
                PHOT{exp}(:,1) = -PHOT{exp}(:,1); 
                rawPHOT{exp}(:,1) = -rawPHOT{exp}(:,1);
            end
            
            % nuke photodiode data beyond some ridiculous sd
            % main point here is to make outlier and peak detection calculations universal
            ridiculous_sd = 5;
            PHOT{exp} = PHOT{exp}.*(abs(normalize(PHOT{exp},2)) < ridiculous_sd);
            
            % butterworth level 4 filter (low pass) for both LFP and PHOT
            % data
            [b_f,a_f] = butter(9,150/resampleFreq{exp}*2);
            LFP{exp} = filter(b_f,a_f,LFP{exp}).';
            [b_f,a_f] = butter(9,100/resampleFreq{exp}*2);
            PHOT{exp} = filter(b_f,a_f,PHOT{exp}).';
        
        end
        
        exp = exp+1;
        
    end
    
end

%% add data to structure according to fly and lit/unlit

FLIES = struct;

for fly = chosenFlies
    
    for block = find(whichFly == fly)
        
        FLIES(fly).block(block).LFP = LFP{block};
        FLIES(fly).block(block).PHOT = PHOT{block};
        FLIES(fly).block(block).rawPHOT = rawPHOT{block};
        FLIES(fly).block(block).times = times{block};
        FLIES(fly).block(block).resampleFreq = resampleFreq{block};
        FLIES(fly).block(block).time_before_peak = time_before_peak(block);
        FLIES(fly).block(block).time_after_peak = time_after_peak(block);
        FLIES(fly).block(block).ISI = ISI(block);
        
    end
    
end

%% analyse data per fly and whether experiment is lit or unlit
for fly = chosenFlies
    
    lit_dark = {'DARK','LIT'};
   
   for lit = [0 1]
       
       thisFlyBlocks = find(whichFly == fly & light_on_dark == lit);
       
       [erp_seq_eff,semSeq,nERPs,meanERPS, meanPHOT] = processFly(FLIES(fly), thisFlyBlocks, lit, ISI);

       FLIES(fly).(lit_dark{lit+1}).erp_seq_eff = erp_seq_eff;
       FLIES(fly).(lit_dark{lit+1}).semSeq = semSeq;
       FLIES(fly).(lit_dark{lit+1}).nERPs = nERPs;
       FLIES(fly).(lit_dark{lit+1}).meanERPS = meanERPS;
       FLIES(fly).(lit_dark{lit+1}).meanPHOT = meanPHOT;
       
   end
 
end

%% plot average sequential dependencies for all selected flies together

for lit = [0 1]
    
    lit_dark = {'DARK','LIT'};

    seq_eff = zeros(16,length(chosenFlies));
    n = zeros(1,length(chosenFlies));
    
    for fly = 1:length(chosenFlies)
        
        figure;
        create_seq_eff_plot(FLIES(chosenFlies(fly)).(lit_dark{lit+1}).erp_seq_eff.',[],'errors',FLIES(chosenFlies(fly)).(lit_dark{lit+1}).semSeq.');
        saveas(gcf,['fly_' num2str(chosenFlies(fly)) '_' lit_dark{lit+1} '.png']);
        
%         seq_eff(:,fly) = FLIES(chosenFlies(fly)).(lit_dark{lit+1}).erp_seq_eff.';
%         n(fly) = sum(FLIES(chosenFlies(fly)).(lit_dark{lit+1}).nERPs);
%         seq_eff(:,fly) = seq_eff(:,fly)*n(fly);
    
    end
    
%     figure;
%     create_seq_eff_plot(sum(seq_eff,2)/sum(n),[]);
%     saveas(gcf,['all_flies_' lit_dark{lit+1} '.png']);
    
end


%% plot mean ERP for lit vs unlit for each fly

for fly = 1:length(chosenFlies)
   
    figure;
    hold on
    plot(normalize(sum(FLIES(chosenFlies(fly)).LIT.meanERPS,2)/16));
    plot(normalize(sum(FLIES(chosenFlies(fly)).LIT.meanPHOT,2)/16));
    legend('ERP LIT','PHOT LIT');
    saveas(gcf,['meanERP_fly_' num2str(chosenFlies(fly)) '_LIT.png']);
    
    figure;
    hold on
    plot(normalize(sum(FLIES(chosenFlies(fly)).DARK.meanERPS,2)/16));
    plot(normalize(sum(FLIES(chosenFlies(fly)).DARK.meanPHOT,2)/16));
    legend('ERP DARK','PHOT DARK');
    
    saveas(gcf,['meanERP_fly_' num2str(chosenFlies(fly)) '_DARK.png']);
    
end