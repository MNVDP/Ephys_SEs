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

fly_record = readtable('fly_record');

%% restrict to 1.25 Hz case
fly_record = fly_record(fly_record.Frequency == 1.25,:);

%remove dead flies and flies with legs
fly_record = fly_record(1:31,:);

dates = unique(fly_record.Date);

%% choose flies and experiments
whichFly =      fly_record.Fly.';
flySet = unique(whichFly);

n_blocks = length(whichFly);

% chosenFlies = [14];
chosenFlies = flySet; % choose all flies

%TODO: handle cases where the block number is the same across flies
% chosenBlocks = [23 24];
chosenBlocks = unique(fly_record.Block.');% do not choose specific blocks

chosenOnes = ismember(fly_record.Block.', chosenBlocks) & ismember(fly_record.Fly.', chosenFlies);

%% experimental parameters and window calculation
ISI = fly_record.ISI;

time_before_peak = fly_record.SDT/2;
time_after_peak = ISI/2;

%light_on_dark = 1 means a bright bar over a dark background was used
light_on_dark = strcmp(fly_record.Condition,'LIT').';
% chosenOnes = 1-light_on_dark; % choose all lit flies

%% TODO: load data directly into structure

% for fly = chosenFlies
%    
%     
%     
% end
    
%% load data of chosen experiments into cell arrays
LFP = {}; PHOT = {}; times = {}; resampleFreq = {}; rawPHOT = {};

exp = 1;

for d = 1:length(dates)
    
    currentDateDirectory = ['../Output/' datestr(dates(d),'ddmmyy') '/LFP'];

    % get blocks for current date
    blocks = fly_record.Block(fly_record.Date == dates(d));
    
    for b = 1:length(blocks)
        
        if chosenOnes(exp)

            load([currentDateDirectory '/Analyzed_TagTrials_block' num2str(blocks(b)) '/' datestr(dates(d),'ddmmyy') '_chunk_0']);

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
            [b_f,a_f] = butter(9,80/resampleFreq{exp}*2);
            LFP{exp} = filter(b_f,a_f,LFP{exp}).';
            [b_f,a_f] = butter(9,50/resampleFreq{exp}*2);
            PHOT{exp} = filter(b_f,a_f,PHOT{exp}).';
        
        end
        
        exp = exp + 1;
        
    end
    
end

%% add data to structure according to fly and lit/unlit
FLIES = struct;

for fly = chosenFlies

    for block = find(whichFly == fly & chosenOnes)

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
       
       thisFlyBlocks = find(whichFly == fly & light_on_dark == lit & chosenOnes);
       
       [erp_seq_eff,erp_seq_eff_latency,positive_amplitude,negative_amplitude,semSeq,nERPs,meanERPS, meanPHOT] = processFly(FLIES(fly), thisFlyBlocks, lit, 0);

       FLIES(fly).(lit_dark{lit+1}).positive_amplitude = positive_amplitude;
       FLIES(fly).(lit_dark{lit+1}).negative_amplitude = negative_amplitude;
       FLIES(fly).(lit_dark{lit+1}).erp_seq_eff_latency = erp_seq_eff_latency;
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
        
        % amplitude sequential effects
        figure;
        create_seq_eff_plot(FLIES(chosenFlies(fly)).(lit_dark{lit+1}).erp_seq_eff.',[],'errors',FLIES(chosenFlies(fly)).(lit_dark{lit+1}).semSeq.');
        saveas(gcf,['Results/Amplitude/fly_' num2str(chosenFlies(fly)) '_' lit_dark{lit+1} '.png']);

        % latency sequential effects
        figure;
        create_seq_eff_plot(FLIES(chosenFlies(fly)).(lit_dark{lit+1}).erp_seq_eff_latency.',[],'errors',FLIES(chosenFlies(fly)).(lit_dark{lit+1}).semSeq.');
        saveas(gcf,['Results/Latency/fly_' num2str(chosenFlies(fly)) '_' lit_dark{lit+1} '_latency.png']);
        
        % positive amplitude SEs
        figure;
        create_seq_eff_plot(FLIES(chosenFlies(fly)).(lit_dark{lit+1}).positive_amplitude.',[],'errors',FLIES(chosenFlies(fly)).(lit_dark{lit+1}).semSeq.');
        saveas(gcf,['Results/Positive amplitude/fly_' num2str(chosenFlies(fly)) '_' lit_dark{lit+1} '_positive_amplitude.png']);
        
        % negative amplitude SEs
        figure;
        create_seq_eff_plot(FLIES(chosenFlies(fly)).(lit_dark{lit+1}).negative_amplitude.',[],'errors',FLIES(chosenFlies(fly)).(lit_dark{lit+1}).semSeq.');
        saveas(gcf,['Results/Negative amplitude/fly_' num2str(chosenFlies(fly)) '_' lit_dark{lit+1} '_negative_amplitude.png']);
        
        
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