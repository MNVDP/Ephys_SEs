%this function does all the pre-processing of the RT data before it is analysed. It:

%(1) separates RTs according to the previous n stimuli and the current stimulus, resulting in a (2^n x num_trials) matrix

%(2) outputs a structure with the data for each subject and also everyone grouped

function [data] = process_online_2AFC_RTdata(raw_data,n_trials,n_blocks,n_back)

n_seq = 2^n_back;

sequenceLength = n_trials*n_blocks;

n_subjects = length(raw_data);

%% create an auxiliary logical array to quickly remove first 4 elements of each block

first_four_index = createFirstFourIndex(n_trials,n_blocks);

%% remove data from first block

% for s = 1:length(raw_data)
% 
%     if length(raw_data(s).responses) > sequenceLength
% 
%         raw_data(s).responses(1:n_trials) = []; raw_data(s).stimuli(1:n_trials) = []; raw_data(s).rts(1:n_trials) = [];
% 
%     end
% 
% end

%%

data.individual_subjects = struct([]); data.grouped_data = struct;

for i = 1:n_subjects

    RTs = zeros(n_seq,sequenceLength); Errors = zeros(n_seq,sequenceLength);
    
    %
    randomSequence = raw_data(i).stimuli; reactionTimes = raw_data(i).rts; keyPressed = raw_data(i).responses;
    
    %figure out which key was pressed for which sequence element (just in case)
    [keyPressed] = sortKeysPressed(randomSequence,keyPressed,2);
    
    %make the sequences binary (0s and 1s) to use in the next step
    %randomSequence = randomSequence-1; 
    keyPressed = keyPressed-1;
    
    %sort the RTs into the appropriate categories depending on the 4 previous stimuli
    %same for the errors
    for n = n_back:sequenceLength
        
        RTs(bin2dec(num2str(randomSequence(n-(n_back-1):n)))+1,n) = reactionTimes(n);
        
        Errors(bin2dec(num2str(randomSequence(n-(n_back-1):n)))+1,n) = ~(randomSequence(n)==keyPressed(n));
        
    end
    
    %clean the RTs and Errors of the first four stimuli of each block
    %NOTE: the reason why I make them 0 instead of removing them is just in case I remove forward errors
    %so that I don't lose valid trials if the last element in a block is an error
    RTs(:,first_four_index) = 0; Errors(:,first_four_index) = 0;
    
    %data for each individual subject
    data.individual_subjects(i).mTurkID = raw_data(i).mTurkID;
    data.individual_subjects(i).RTs = RTs; 
    data.individual_subjects(i).Errors = Errors; 
    data.individual_subjects(i).keyPressed = keyPressed; 
    data.individual_subjects(i).randomSequence = randomSequence;
    
    %add the mean and median RT of each subject to the structure
%     data.individual_subjects(i).meanRT = mean(sum(RTs)); 
%     data.individual_subjects(i).medianRT = median(sum(RTs));
    
end

RTs = []; Errors = []; keyPressed = []; randomSequence = [];

%group everything
for i = 1:n_subjects
    RTs = [RTs data.individual_subjects(i).RTs]; %#ok<AGROW>
    Errors = [Errors data.individual_subjects(i).Errors]; %#ok<AGROW>
    keyPressed = [keyPressed data.individual_subjects(i).keyPressed]; %#ok<AGROW>
    randomSequence = [randomSequence data.individual_subjects(i).randomSequence]; %#ok<AGROW>
end

%organise the pooled data into a structure
data.grouped_data.RTs = RTs; 
data.grouped_data.Errors = Errors; 
data.grouped_data.keyPressed = keyPressed; 
data.grouped_data.randomSequence = randomSequence;