%this function analyses a block of RTs, already separated into 5 long stimuli sequences it does:

%(1) removes NaN's, negative values and outliers

%(2) removes errors from RTs and (optionally) the 4 RTs following an error

%(3) outputs a structure with vectors of mean and median RTs, stddev of these and Error rates, 
%    organised according to the literature (5 stimuli)

function [data] = analyse_2AFC_RTdata(RTs, Errors,remove_forward_errors,outliers)

data = struct;

%group sequences 2 by 2 (00001 is the same as 11110 and so on)
RTs = RTs + flipud(RTs); Errors = Errors + flipud(Errors);
RTs(17:end,:) = []; Errors(17:end,:) = [];

%remove negative values and NaN's from errors and RTs (from errors also because we don't want errors due to RT box problems)
Errors(RTs < 0) = 0; RTs(RTs < 0) = 0;

Errors(isnan(RTs)) = 0; RTs(isnan(RTs)) = 0;

%calculate error rate (this has to be done before removing the errors from the RTs)
error_rate = sum(Errors,2)./sum(RTs~=0,2);

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

%create vectors of means, medians, standard deviations and error rates
meanRT = zeros(1,16); medianRT = zeros(1,16); stdev_RT = zeros(1,16);

for i =1:16
    meanRT(i) = mean(RTs(i,RTs(i,:)~=0));
    medianRT(i) = median(RTs(i,RTs(i,:)~=0)); 
    stdev_RT(i) = std(RTs(i,RTs(i,:)~=0));
end

%plotting order from the literature
order = [1 16 8 9 4 13 5 12 2 15 7 10 3 14 6 11];

data.RT_pattern.meanRTs = meanRT(order); 
data.RT_pattern.medianRTs = medianRT(order); 
data.RT_pattern.stdevRTs = stdev_RT(order); 
data.RT_pattern.error_rates = error_rate(order);

%keep the RTs clean of outliers and mistakes
data.cleanRTs = RTs;

%global mean and median RT for this subject
data.meanRT = mean(RTs(RTs ~= 0));
data.medianRT = median(RTs(RTs ~= 0));

%keep the outlier bounds used
data.outlier_bounds = outliers;