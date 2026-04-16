%this function create a logical index of the first four trials of each block in a 2AFC task
function [first_four_index] = createFirstFourIndex(n_trials,n_blocks)

sequenceLength = n_trials*n_blocks;

first_four_index = zeros(1,sequenceLength);

for i = 1:n_trials:sequenceLength-n_trials+1
        first_four_index(i:i+3) = 1;
end

first_four_index = logical(first_four_index);