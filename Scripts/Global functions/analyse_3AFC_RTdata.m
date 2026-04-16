%this function analyses a block of RTs, already separated into 5 long stimuli sequences it does:

%(1) removes NaN's and negative values

%(2) removes errors from RTs and (optionally) the 4 RTs following an error

%(3) outputs a structure with vectors of mean and median RTs, stddev of these and Error rates, 
%    organised according to the literature (5 stimuli)

function [data] = analyse_3AFC_RTdata(RTs, Errors,remove_forward_errors,outliers)

load index_trinomial

data = struct;

%remove negative values and NaN's from errors and RTs (from errors also because we don't want errors due to RT box problems)
Errors(RTs < 0) = 0; RTs(RTs < 0) = 0;

Errors(isnan(RTs)) = 0; RTs(isnan(RTs)) = 0;

%number of valid responses for each sequence
n_RTs = sum(RTs~=0,2);

%calculate error rate (this has to be done before removing the errors from the RTs)
error_rate = zeros(1,length(index_trinomial)); %#ok<USENS>
for i = 1:length(index_trinomial)
    error_rate(i) = sum(sum(Errors(index_trinomial{i},:)))/sum(n_RTs(index_trinomial{i}));
end

%remove errors from RTs
if remove_forward_errors
    
    %remove all the 4 trials after an error; 
    %NOTE: to do this, make sure that the first four trials of each block were equalled to 0, rather than removed
    forward_errors = zeros(1,length(Errors));
    
    for i = find(sum(Errors))
        forward_errors(i:i+4) = 1;
    end 
    
    RTs(:,logical(forward_errors)) = 0;
    
else
    RTs(logical(Errors)) = 0;
end

%remove bad outliers (from visual inspection)
RTs(RTs < outliers(1) | RTs > outliers(2)) = 0;

medianRT = zeros(1,length(index_trinomial));
meanRT = zeros(1,length(index_trinomial));
stdev_RT = zeros(1,length(index_trinomial));

for i = 1:length(index_trinomial)
    aux = RTs(index_trinomial{i},:);
    medianRT(i) = median(aux(aux~=0));
    meanRT(i) = mean(aux(aux~=0));
    stdev_RT(i) = std(aux(aux~=0));
end

data.meanRT = meanRT; 
data.medianRT = medianRT; 
data.stdev_RT = stdev_RT; 
data.error_rate = error_rate;
data.RTs = RTs;