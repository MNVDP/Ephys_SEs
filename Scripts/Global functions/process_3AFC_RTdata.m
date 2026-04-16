%this function does all the pre-processing of the RT data before it is analysed. It:

%(1) separates RTs according to the previous 4 stimuli and the current stimulus

%(2) outputs a structure with the data for each subject and also everyone grouped

function [data] = process_3AFC_RTdata(list_of_subjects,list_of_dates,n_trials,n_blocks)

n_subjects = length(list_of_subjects); sequenceLength = n_trials*n_blocks;

%% join the two separate files for each participant

cd data

join_data;

cd ..

%% create an auxiliary logical array to quickly remove first 4 elements of each block
first_four_index = zeros(1,sequenceLength);
for i = 1:n_trials:sequenceLength-n_trials+1
        first_four_index(i:i+3) = 1;
end

first_four_index = logical(first_four_index);

data.individual_subjects = struct([]); data.grouped_data = struct;

%%

for i = 1:n_subjects
    
    load(strcat('data/',list_of_subjects{i},'/',list_of_subjects{i},list_of_dates{i}),'reactionTime','randomSequence','keyPressed');

    RTs = zeros(3^5,sequenceLength); Errors = zeros(3^5,sequenceLength);
    
    %figure out which key was pressed for which sequence element
    [keyPressed] = sortKeysPressed(randomSequence,keyPressed,3);
    
    %make the sequences ternary (0s and 1s) to use in the next step
    randomSequence = randomSequence-1; keyPressed = keyPressed-1;
    
    %sort the RTs into the appropriate categories depending on the 4 previous stimuli
    %same for the errors
    for n = 5:sequenceLength
        
        RTs(base2dec(num2str(randomSequence(n-4:n),'%g'),3)+1,n) = reactionTime(n);
        
        Errors(base2dec(num2str(randomSequence(n-4:n),'%g'),3)+1,n) = randomSequence(n)~=keyPressed(n);
        
    end
    
    %clean the RTs and Errors of the first four stimuli of each block
    %NOTE: the reason why I make them 0 instead of removing them is just in case I remove forward errors
    %so that I don't lose valid trials if the last element in a block is an error
    RTs(:,first_four_index) = 0; Errors(:,first_four_index) = 0;
     
    %data for each individual subject
    data.individual_subjects(i).name = list_of_subjects{i};
    data.individual_subjects(i).date = list_of_dates{i};
    data.individual_subjects(i).RTs = RTs; 
    data.individual_subjects(i).Errors = Errors; 
    data.individual_subjects(i).keyPressed = keyPressed; 
    data.individual_subjects(i).randomSequence = randomSequence;
    
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