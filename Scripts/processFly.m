% this function processes a set of blocks, usually corresponding to a single fly
% it concatenates the data for all blocks and does a sequential
% dependencies analysis
function [erp_seq_eff,erp_seq_eff_latency,positive_amplitude,negative_amplitude,semSeq,nERPs,meanERPS,meanPHOTs] = processFly(fly, blocks, light_on_dark, aux_plots)
    
    n_blocks = length(blocks);
    
    %collect data for this fly
    for b = 1:n_blocks
       LFP{b} = fly.block(blocks(b)).LFP; %#ok<*AGROW>
       PHOT{b} = fly.block(blocks(b)).PHOT; 
       times{b} = fly.block(blocks(b)).times;  %#ok<NASGU>
       resampleFreq{b} = fly.block(blocks(b)).resampleFreq;
       time_before_peak{b} = fly.block(blocks(b)).time_before_peak;
       time_after_peak{b} = fly.block(blocks(b)).time_after_peak;
       ISI{b} = fly.block(blocks(b)).ISI;
    end
    
    LOCS = {};
    randomSequence = {};
    badTrials = {};

    for exp = 1:n_blocks

        % find peaks
        [PKS_PHOT1,LOCS_PHOT1] = findpeaksbase(normalize(PHOT{exp}(1,:)) , 'MinPeakHeight' , 2 , 'MinPeakDistance' , 1/2*ISI{exp}*resampleFreq{exp} );
        [PKS_PHOT2,LOCS_PHOT2] = findpeaksbase(normalize(PHOT{exp}(2,:)) , 'MinPeakHeight' , 2 , 'MinPeakDistance' , 1/2*ISI{exp}*resampleFreq{exp} );

        %remove outliers from PHOT
        outlier_sd = 2;
        [LOCS_PHOT1, PKS_PHOT1] = removePHOToutliers(LOCS_PHOT1, PKS_PHOT1, outlier_sd);
        [LOCS_PHOT2, PKS_PHOT2] = removePHOToutliers(LOCS_PHOT2, PKS_PHOT2, outlier_sd);

        % plot peak detection for each photodiode as a sanity check
        if aux_plots
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
        end
            
        % fuse locations of PHOT1 and PHOT2 (I figured this was quicker than concatenating and sorting)
        LOCS{exp} = zeros(size(PHOT{exp}(1,:)));
        LOCS{exp}(LOCS_PHOT1) = LOCS_PHOT1; LOCS{exp}(LOCS_PHOT2) = LOCS_PHOT2;
        LOCS{exp} = LOCS{exp}(logical(LOCS{exp}));

        %we must get rid of trials where we could not get a peak and the
        %subsequent four trials
        badLOCS = find(diff(LOCS{exp}) > 1.5*ISI{exp}*resampleFreq{exp}) + 1; % index of trials where gap was longer than ISI
        badLOCS = LOCS{exp}(badLOCS);
        badTrials{exp} = zeros(size(PHOT{exp}(1,:)));
        badTrials{exp}(badLOCS) = 1;

        % infer random sequence (0 - left; 1 - right)
        randomSequence{exp} = zeros(size(PHOT{exp}(1,:)));
        randomSequence{exp}(LOCS_PHOT1) = 2; randomSequence{exp}(LOCS_PHOT2) = 1;
        badTrials{exp} = badTrials{exp}(logical(randomSequence{exp})); % careful order is important here
        randomSequence{exp} = randomSequence{exp}(logical(randomSequence{exp})) - 1;

        %remove 4 trials after a bad one
        badTrialsIndex = find(badTrials{exp});
        badTrials{exp}([badTrialsIndex+1 badTrialsIndex+2 badTrialsIndex+3 badTrialsIndex+4]) = 1;

        % FOR TESTING
    %     LOCS{exp} = LOCS{exp}(1:end-2);
    %     randomSequence{exp} = randomSequence{exp}(1:end-2);

        % histogram of interval between peaks (should have one tight peak)
        if aux_plots
            figure;
            histogram(diff(LOCS{exp}));
        end
            
    end

    %% sort data according to previous sequence
    n_back = 5; n_seq = 2^n_back; 

    ERPS = {}; STDs = {}; meanERP = {}; seqPHOT = {};

    for exp = 1:length(LFP)
    
        window = floor([-time_before_peak{exp}*resampleFreq{1}, time_after_peak{exp}*resampleFreq{1}]);

        sequenceLength = length(randomSequence{exp});

        ERPS{exp} = zeros(length(window(1):window(2)), n_seq, sequenceLength);
        seqPHOT{exp} = zeros(length(window(1):window(2)), n_seq, sequenceLength);
        
        for n = n_back:sequenceLength

            % decimal value of binary sequence of length n_back
            seq = bin2dec(num2str(randomSequence{exp}(n-n_back+1:n)))+1;

            % stack ERPs and PHOTs along third dimension (first two dims are sequence and
            % time respectively)
            ERPS{exp}(:, seq, n) = LFP{exp}(LOCS{exp}(n) + window(1) : LOCS{exp}(n) + window(2));
            seqPHOT{exp}(:, seq, n) = normalize(PHOT{exp}(2-randomSequence{exp}(n), LOCS{exp}(n) + window(1) : LOCS{exp}(n) + window(2) ));
       
        end

        % matrix with all ERPs irrespective of sequence
        all_erps = squeeze(sum(ERPS{exp},2));% squeeze removes first dimension

        %calculate mean and SEM for outlier calculations
        meanERP{exp} = mean(all_erps, 2);
        STDs{exp} = std(all_erps, [], 2);

        n_sd = 3;

        % remove ERPs beyond n_sd (TODO: OPTIMISE)
        outliers = all_erps < meanERP{exp} - n_sd*STDs{exp} | all_erps > meanERP{exp} + n_sd*STDs{exp};

        good_erps = ~logical(sum(outliers));

        % remove ERP outliers
        ERPS{exp} = ERPS{exp}(:,:,good_erps);
        seqPHOT{exp} = seqPHOT{exp}(:,:,good_erps);
        badTrials{exp} = badTrials{exp}(good_erps);

        % onion plot showing all ERPs
        all_erps = all_erps(:,good_erps);
        if aux_plots
            figure;
            plot(all_erps,'b');
            hold on;
            plot(mean(all_erps,2), 'r');
        end
    
    end

    %% sequential effects analysis

    total_length = 0;

    %the length here is the number of blocks as LFP is a cell array
    %of length equal to the number of blocks
    for exp = 1:length(LFP)
        total_length = total_length + size(ERPS{exp},3);
    end 
    
    % concatenate ERPs from different "experiments" (blocks)
    allERPs = zeros(length(window(1):window(2)), n_seq, total_length);
    allPHOTs = zeros(length(window(1):window(2)), n_seq, total_length);
    
    start_index = 1; goodTrials = [];

    % these are already separated by sequence so in order to group by block
    % it is only necessary to stack along third dimension
    for exp = 1:n_blocks

        allERPs(:,:,start_index:start_index + size(ERPS{exp},3) - 1) = ERPS{exp};
        allPHOTs(:,:,start_index:start_index + size(ERPS{exp},3) - 1) = seqPHOT{exp};

        start_index = start_index + size(ERPS{exp},3);

        goodTrials = [goodTrials 1-badTrials{exp}];

    end
    
    %%

    % get rid of bad trials (trials with too long gaps between peaks)
    allERPs = allERPs(:,:,logical(goodTrials));
    allPHOTs = allPHOTs(:,:,logical(goodTrials));
    
    % for plotting PHOT the right way round
%     if ~light_on_dark
%         allPHOTs = -allPHOTs;
%     end
    
    % onion plot of the photodiode data
    if aux_plots
        figure;
        plot(squeeze(sum(allPHOTs,2)),'b');
        hold on
        plot(mean(squeeze(sum(allPHOTs,2)),2),'r');
    end
        
    % in preparation for calculating the mean
    allERPs(allERPs == 0) = nan;
    allPHOTs(allPHOTs == 0) = nan;

    % mean across third dimension (ERP or PHOT stack)
    meanERPS = mean(allERPs, 3, 'omitnan');
    meanPHOTs = mean(allPHOTs, 3, 'omitnan');

    %number of ERPs for each sequence
    nERPs = sum(~isnan(allERPs(1,:,:)), 3);
    
    % standard error of the mean for all ERPs separated by sequence
    semERPs = std(allERPs,[],3,'omitnan')/sqrt(sum(nERPs));
    
    %group sequences 2 by 2 (00001 is the same as 11110 and so on)
    meanERPS = meanERPS + fliplr(meanERPS);
    meanPHOTs = meanPHOTs + fliplr(meanPHOTs);
    semERPs = semERPs + fliplr(semERPs);

    % remove the last 16 sequences after flipping and adding
    meanERPS(:,n_seq/2 + 1:end) = [];
    meanERPS = meanERPS/2;
    meanPHOTs(:,n_seq/2 + 1:end) = [];
    meanPHOTs = meanPHOTs/2;
    
    %not sure whether it is valid to average SEMs but it should not matter
    %too much
    semERPs(:,n_seq/2 + 1:end) = [];
    semERPs = semERPs/2;
    
    % reorder according to the literature
    meanERPS = meanERPS(:,seq_eff_order(n_back));
    meanPHOTs = meanPHOTs(:,seq_eff_order(n_back));

    % get the maxima and minima for all sequences
    [max_erp, ind_max_erp] = max(meanERPS);
    [min_erp, ind_min_erp] = min(meanERPS);
    
    % get the maxima of the diff of the PHOT to mark stimulus onset
    [~, stim_onset] = max(diff(meanPHOTs));

    %standard errors of the mean for the maxima (use of linear indexing here)
    semSeq = (semERPs(sub2ind(size(semERPs),ind_max_erp,1:16)) + semERPs(sub2ind(size(semERPs),ind_min_erp,1:16)))/2;
    semSeq = semSeq(seq_eff_order(n_back));
    
    % plot of the 16 sequences together
    %     plot(meanERPS);
    
    % plot ERPs for each sequence seaprately in a 4x4 plot
    % for each sequence, highlight where the maxima (red) and minima (blue) are located 
    if aux_plots
        figure;
        y_limit = [min(meanERPS(:)) max(meanERPS(:))];

        load('binomial_x_labels_latex_alt_rep.mat','binomial_x_labels_latex');

        %this is just to help turn horizontal sequences into vertical ones
        ind_horiz = sub2ind(size(binomial_x_labels_latex{1}),1:4,[1 1 1 5]);

        for i = 1:16
           subplot(4,4,i);
           plot(meanERPS(:,i));
           ylim(y_limit);
           hold on;
           scatter(ind_max_erp(i), 0,40,'r','filled');
           scatter(ind_min_erp(i), 0,40,'b','filled');
           title(binomial_x_labels_latex{i}(ind_horiz));
        end
    end
        
    % amplitude of the ERP per sequence
    erp_seq_eff = max_erp - min_erp;
    
    % latency from stimulus onset to peak
    % this takes the resample frequency of the first block
    for i = 1:16
        % if maximum comes before minimum ERP is positive going
        if (ind_min_erp(i)-ind_max_erp(i)) > 0
            erp_seq_eff_latency(i) = (ind_max_erp(i) - stim_onset(i))/resampleFreq{1};
        else
            erp_seq_eff_latency(i) = (ind_min_erp(i) - stim_onset(i))/resampleFreq{1};
        end
    end
    
    % positive amplitude
    positive_amplitude =  max_erp-meanERPS(1,:);
    
    % negative amplitude
    negative_amplitude =  min_erp-meanERPS(1,:);

end % end processing