%this function sorts out what keys were pressed for which sequence element
%it then returns the sequence of keys pressed with numbers matching the corresponding sequence elements
%   WARNING: THIS MAY MALFUNCTION FOR VERY LOW RSI AS ERROR RATES CAN BE HIGHER THAN 50%
function [keypressed] = sortKeysPressed(randomsequence,keypressed,n_keys)

% load Joey.mat
% 
% randomsequence = randomSequence; keypressed = keyPressed; n_keys = 2;

%what keys were pressed?
keyset = unique(keypressed);

%remove nan's from keyset (some people have a lot of these due to Cedrus RT box's problems)
keyset = keyset(~isnan(keyset));

%turn the numbers of the keys pressed to ridiculous values to prevent any overlap when substituting in the end
for i = 1:length(keyset)
    keypressed(keypressed == keyset(i)) = 40+i;
    keyset(i) = 40+i;
end

%if any additional keys were pressed by mistake, remove them from the set to be analysed
if length(keyset) ~= n_keys
    
    %this assumes that keys pressed by accident are always less frequent
    for i = 1:length(keyset)-n_keys
        
        %get the index of the minimum value of the count of the set of keys pressed (returns the first if more than 1 min)
        [~,ind_key] = min(histc(keypressed,keyset));
        
        %remove the key with small press count from the set of keys
        keyset = setdiff(keyset,keyset(ind_key));
        
    end
end

all_sets = perms(keyset); count = zeros(1,length(keyset));

%find the best match of the set of keys pressed and sequence elements
for i = 1:length(all_sets)
    
    aux_keypressed = keypressed;
    
    for j = 1:n_keys
        aux_keypressed(aux_keypressed == all_sets(i,j)) = j;
    end
    
    count(i) = nnz(aux_keypressed == randomsequence);
    
end

%get the right set
[~,ind_set] = max(count); right_set = all_sets(ind_set,:);

%make the changes in the keypressed sequence
for i = 1:n_keys
    keypressed(keypressed == right_set(i)) = i;
end