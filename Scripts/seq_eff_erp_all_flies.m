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
dataPath = "D:\group_swinderen\Dinis\Output";

dates = extractfield(dir(dataPath), 'name'); dates = dates(3:end); % get rid of . and ..

% sort dates
[~,ind_dates] = sort(datenum(dates,'ddmmyy'));
dates = dates(ind_dates);

%% choose flies and experiments
chosenOnes = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  1  0];
flies =      [1 1 2 2 3 3 3 4 4 5 5 6 6 6 7 7 8 8 8 9 9 10 10 10 11 11 11 12 12 12 13 13];

flySet = unique(flies);

%% individual time windows for each fly
time_before_peak = 0.05*ones(size(chosenOnes)); % 50 ms before seems to work universally well
time_after_peak = .2*ones(size(chosenOnes)); % different flies seem to have different length ERPs

%% HACK!!! 
%TODO: add tag to experiment script stating whether it is B on D or D on B
%light_on_dark = 1 means a bright bar over a dark background was used
light_on_dark = [1 0 1 0 1 0 1 1 0 1 0 1 0 1 1 0 1 0 1 1 0 0 1 0 0 1 0 1 0 1 1 0];
% chosenOnes = 1-light_on_dark;

time_after_peak = time_after_peak(logical(chosenOnes));% this should be here not above just in case we want all lit/dark
light_on_dark = light_on_dark(logical(chosenOnes));

%% inter-stimulus interval (in seconds)
ISI = .8;

%% load data of chosen experiments into cell arrays
LFP = {}; PHOT = {}; times = {}; resampleFreq = {};

n = 1; exp = 1;

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
            
            disp(dates(d));
            disp(blocks(b));
        
            load([currentDateDirectory '/' blocks{b} '/' dates{d} '_chunk_0']);

            times{n} = EEG.times; %#ok<*SAGROW>
            LFP{n} = EEG.LFP1.data.'; 
            PHOT{n} = EEG.PHOT.data.'; 
            resampleFreq{n} = EEG.srate;
            
            % nuke photodiode data beyond some ridiculous sd
            % main point here is to make outlier and peak detection calculations universal
            ridiculous_sd = 5;
            PHOT{n} = PHOT{n}.*(abs(normalize(PHOT{n},2)) < ridiculous_sd);
            
            % butterworth level 4 filter (low pass at 50 Hz seems to work well)
            [b_f,a_f] = butter(4,50/resampleFreq{n});
            LFP{n} = filter(b_f,a_f,LFP{n}).';
            PHOT{n} = filter(b_f,a_f,PHOT{n}).';
            
            n = n + 1;
        
        end
        
        exp = exp+1;
        
    end
    
end

%% find peaks in photodiode data; remove outliers
LOCS = {};
randomSequence = {};
badTrials = {};

for exp = 1:length(LFP)
    
    % if bright bar on dark background then output of diode should be
    % upward first; however, PHOT2 is inverted
    if light_on_dark(exp)
        PHOT{exp}(2,:) = -PHOT{exp}(2,:);
    else
        PHOT{exp}(1,:) = -PHOT{exp}(1,:); 
    end
    
    % find peaks
    [PKS_PHOT1,LOCS_PHOT1] = findpeaksbase(normalize(PHOT{exp}(1,:)) , 'MinPeakHeight' , 1.5 , 'MinPeakDistance' , 0.5*resampleFreq{exp} );
    [PKS_PHOT2,LOCS_PHOT2] = findpeaksbase(normalize(PHOT{exp}(2,:)) , 'MinPeakHeight' , 1.5 , 'MinPeakDistance' , 0.5*resampleFreq{exp} );
 
    %remove outliers from PHOT
    outlier_sd = 2;
    [LOCS_PHOT1, PKS_PHOT1] = removePHOToutliers(LOCS_PHOT1, PKS_PHOT1, outlier_sd);
    [LOCS_PHOT2, PKS_PHOT2] = removePHOToutliers(LOCS_PHOT2, PKS_PHOT2, outlier_sd);
    
%     figure;
%     plot(PKS_PHOT1);
%     figure;
%     plot(PKS_PHOT2);
    
    figure
    plot(normalize(PHOT{exp}(1,:)));
    hold on
    scatter(LOCS_PHOT1,PKS_PHOT1)
    xlabel('Index')
    title('Detected peaks in phot1')

    figure
    plot(normalize(PHOT{exp}(2,:)));
    hold on
    scatter(LOCS_PHOT2,PKS_PHOT2)
    xlabel('Index')
    title('Detected peaks in phot2')

    % fuse locations of PHOT1 and PHOT2 (I figured this was quicker than concatenating and sorting)
    LOCS{exp} = zeros(1,length(PHOT{exp}(1,:)));
    LOCS{exp}(LOCS_PHOT1) = LOCS_PHOT1; LOCS{exp}(LOCS_PHOT2) = LOCS_PHOT2;
    LOCS{exp} = LOCS{exp}(logical(LOCS{exp}));
   
    %we must get rid of trials where we could not get a peak and the
    %subsequent four trials
    badLOCS = find(diff(LOCS{exp}) > 1.5*ISI*resampleFreq{exp}) + 1; % index of trials where gap was longer than ISI
    badLOCS = LOCS{exp}(badLOCS);
    badTrials{exp} = zeros(1,length(PHOT{exp}(1,:)));
    badTrials{exp}(badLOCS) = 1;
    
    % infer random sequence (0 - left; 1 - right)
    randomSequence{exp} = zeros(1,length(PHOT{exp}(1,:)));
    randomSequence{exp}(LOCS_PHOT1) = 2; randomSequence{exp}(LOCS_PHOT2) = 1;
    badTrials{exp} = badTrials{exp}(logical(randomSequence{exp})); % careful order is important here
    randomSequence{exp} = randomSequence{exp}(logical(randomSequence{exp})) - 1;
    
    %remove 4 trials after a bad one
    badTrialsIndex = find(badTrials{exp});
    badTrials{exp}([badTrialsIndex+1 badTrialsIndex+2 badTrialsIndex+3 badTrialsIndex+4]) = 1;
    
    % FOR TESTING
%     LOCS{exp} = LOCS{exp}(1:end-2);
%     randomSequence{exp} = randomSequence{exp}(1:end-2);
    
    % sanity check to see if we capture all stimuli
    figure;
    histogram(diff(LOCS{exp}));

end

%% analyse sequential dependencies
n_back = 5; n_seq = 2^n_back; 

ERPS = {}; STDs = {}; meanERP = {};

for exp = 1:length(LFP)
    
    window = floor([-time_before_peak(exp)*resampleFreq{1}, time_after_peak(exp)*resampleFreq{1}]);

    sequenceLength = length(randomSequence{exp}) - n_back + 1;
    
    ERPS{exp} = zeros(length(window(1):window(2)), n_seq, sequenceLength);
    
    for n = n_back:sequenceLength

        % decimal value of binary sequence of length n_back
        seq = bin2dec(num2str(randomSequence{exp}(n-n_back+1:n)))+1;
        
        % stack ERPs along third dimension (first two dims are sequence and
        % time respectively)
        ERPS{exp}(:, seq, n-n_back+1) = LFP{exp}(LOCS{exp}(n) + window(1) : LOCS{exp}(n) + window(2));

    end
    
    % matrix with all ERPs irrespective of sequence
    all_erps = squeeze(sum(ERPS{exp},2));% squeeze removes first dimension
    
    %calculate mean and SEM
    meanERP{exp} = mean(all_erps, 2);
    STDs{exp} = std(all_erps, [], 2);
    
    n_sd = 3;
    
    % remove ERPs beyond n_sd
    outliers = all_erps < meanERP{exp} - n_sd*STDs{exp} | all_erps > meanERP{exp} + n_sd*STDs{exp};
    
    good_erps = ~logical(sum(outliers));
    
    % remove ERP outliers
    ERPS{exp} = ERPS{exp}(:,:,good_erps);
    badTrials{exp} = badTrials{exp}(good_erps);
    
    all_erps = all_erps(:,good_erps);
    figure;
    plot(all_erps,'b');
    hold on;
    plot(mean(all_erps,2), 'r');
    
end

%% sequential effects analysis by joining up all ERPs and calculating maxima (probably not good)

total_length = 0;

for exp = 1:length(LFP)
    total_length = total_length + size(ERPS{exp},3);
end 

%concatenate z-scored ERPs
allERPs = zeros(length(window(1):window(2)), n_seq, total_length);

start_index = 1; goodTrials = [];

for exp = 1:length(LFP)
    
    allERPs(:,:,start_index:start_index + size(ERPS{exp},3) - 1) = ERPS{exp};
    
    start_index = start_index + size(ERPS{exp},3);
    
    goodTrials = [goodTrials 1-badTrials{exp}]; %#ok<AGROW>
    
end

% get rid of bad trials
allERPs = allERPs(:,:,logical(goodTrials));

allERPs(allERPs == 0) = nan;

meanERPS = mean(allERPs, 3, 'omitnan');

semERPs = std(allERPs,[],3,'omitnan')/sqrt(size(allERPs,3));

%group sequences 2 by 2 (00001 is the same as 11110 and so on)
meanERPS = meanERPS + fliplr(meanERPS);
semERPs = semERPs + fliplr(semERPs);

meanERPS(:,n_seq/2 + 1:end) = [];
meanERPS = meanERPS/2;

%not sure whether it is valid to average SEMs
semERPs(:,n_seq/2 + 1:end) = [];
semERPs = semERPs/2;
 
[max_erp, ind_max_erp] = max(meanERPS);
[min_erp, ind_min_erp] = min(meanERPS);

%standard errors of the mean for the maxima
semSeq = semERPs(sub2ind(size(semERPs),ind_max_erp,1:16));%use of linear indexing here

figure;
plot(meanERPS);
hold on
scatter(ind_max_erp, zeros(1,length(max_erp)),40,'r','filled');
scatter(ind_min_erp, zeros(1,length(min_erp)),40,'b','filled');

erp_seq_eff = max_erp - min_erp;
 
% correct for baseline
% erp_seq_eff = erp_seq_eff - meanERPS(:,15);

figure;
create_seq_eff_plot(-erp_seq_eff(seq_eff_order(n_back)).',[],'errors',semSeq(seq_eff_order(n_back)).');
saveas(gcf,'all_dark.png');

%% TODO: sequential effects analysis by calculating sequential effects separately and then joining

