%this function analyses a block of RTs, already separated into 5 long stimuli sequences it does:

%(1) removes NaN's, negative values and outliers

%(2) removes errors from RTs and (optionally) the 4 RTs following an error

%(3) outputs a structure with vectors of mean and median RTs, stddev of these and Error rates, 
%    organised according to the literature (5 stimuli)

function [data] = analyse_2AFC_RTdata(data,remove_forward_errors,outliers,n_back)

n_seq = 2^n_back/2;

RTs = data.RTs; Errors = data.Errors;

%group sequences 2 by 2 (00001 is the same as 11110 and so on)
RTs = RTs + flipud(RTs); Errors = Errors + flipud(Errors);
RTs(n_seq+1:end,:) = []; Errors(n_seq+1:end,:) = [];

%remove negative values and NaN's from errors and RTs (from errors also because we don't want errors due to RT box problems)
Errors(RTs < 0) = 0; RTs(RTs < 0) = 0; Errors(isnan(RTs)) = 0; RTs(isnan(RTs)) = 0;

%calculate error rate (this has to be done before removing the errors from the RTs)
errors_seq = sum(Errors,2); total_seq = sum(RTs~=0,2);
error_rate = errors_seq./total_seq;

%calculate the standard error of the mean error rate
std_error_error_rate = zeros(1,n_seq);
for i =1:n_seq
    aux = [ones(1,errors_seq(i)) zeros(1,total_seq(i))];
    std_error_error_rate(i) = std(aux)/sqrt(length(aux));
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

% do a log transform of RTs
logRTs = RTs;

logRTs(RTs ~= 0) = log(RTs(RTs ~= 0));

%% analyse untransformed RTs

%remove bad outliers (from visual inspection)
RTs(RTs < outliers(1) | RTs > outliers(2)) = 0;

%create vectors of means, medians, standard deviations and error rates
meanRT = zeros(1,n_seq); medianRT = zeros(1,n_seq); 

stdevRT = zeros(1,n_seq); skewnessRT = zeros(1,n_seq); kurtosisRT = zeros(1,n_seq); 

%a vector with the total number of each of the sequences USED TO CALCULATE MEAN RTS (DOES NOT INCLUDE ERRORS)
n_all_seq = sum(RTs~=0,2);

for i =1:n_seq
    meanRT(i) = mean(RTs(i,RTs(i,:)~=0));
    medianRT(i) = median(RTs(i,RTs(i,:)~=0)); 
    stdevRT(i) = std(RTs(i,RTs(i,:)~=0));
    skewnessRT(i) = skewness(RTs(i,RTs(i,:)~=0));
    kurtosisRT(i) = kurtosis(RTs(i,RTs(i,:)~=0));
end

%% analyse log transformed RTs

logMeanRT = zeros(1,n_seq); logMedianRT = zeros(1,n_seq); 

logStdevRT = zeros(1,n_seq); logSkewnessRT = zeros(1,n_seq); logKurtosisRT = zeros(1,n_seq); 

%calculate the means and stdvs of each row
for i =1:n_seq
    logMeanRT(i) = mean(logRTs(i,logRTs(i,:)~=0));
    logStdevRT(i) = std(logRTs(i,logRTs(i,:)~=0));
end

%remove outliers as 2X stdv
for i = 1:n_seq
    logRTs(i,(logRTs(i,:) > (logMeanRT(i)+2*logStdevRT(i))) | (logRTs(i,:) < (logMeanRT(i)-2*logStdevRT(i)))) = 0;
end

%recalculate means and stdev (and medians now)
for i =1:n_seq
    logMeanRT(i) = mean(exp(logRTs(i,logRTs(i,:)~=0)));
    logMedianRT(i) = median(exp(logRTs(i,logRTs(i,:)~=0)));
    logStdevRT(i) = std(exp(logRTs(i,logRTs(i,:)~=0)));
    logSkewnessRT(i) = skewness(exp(logRTs(i,logRTs(i,:)~=0)));
    logKurtosisRT(i) = kurtosis(exp(logRTs(i,logRTs(i,:)~=0)));
end

%% 

%plotting order from the literature
order = seq_eff_order(n_back);

data.seq_eff_pattern.meanRTs = meanRT(order); 
data.seq_eff_pattern.medianRTs = medianRT(order); 
data.seq_eff_pattern.stdevRTs = stdevRT(order); 
data.seq_eff_pattern.skewnessRTs = skewnessRT(order); 
data.seq_eff_pattern.kurtosisRTs = kurtosisRT(order);

data.seq_eff_pattern.logMeanRTs = logMeanRT(order); 
data.seq_eff_pattern.logMedianRTs = logMedianRT(order); 
data.seq_eff_pattern.logStdevRTs = logStdevRT(order); 
data.seq_eff_pattern.logSkewnessRTs = logSkewnessRT(order); 
data.seq_eff_pattern.logKurtosisRTs = logKurtosisRT(order);

data.seq_eff_pattern.error_rates = error_rate(order);
data.seq_eff_pattern.std_error_error_rate = std_error_error_rate(order);

%keep the RTs clean of outliers and mistakes
data.cleanRTs = RTs;
data.logRTs = logRTs;

data.n_all_seq = n_all_seq(order);

%global mean and median RT for this subject
data.meanRT = mean(RTs(RTs ~= 0));
data.medianRT = median(RTs(RTs ~= 0));

%keep the outlier bounds used
data.outlier_bounds = outliers;