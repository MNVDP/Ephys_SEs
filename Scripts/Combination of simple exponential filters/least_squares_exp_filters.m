%this function finds the predictive probabilities for a given data set depending on a set of parameters
%this is the function that is minimised when fitting the model to the data
%it returns a sum of least square errors between the data and the model
function [least2] = least_squares_exp_filters(b,a,alpha,data)
    
global rt_prediction

all_seq =  [1 1 1 1 1
            1 0 0 0 0
            1 1 0 0 0
            1 0 1 1 1
            1 1 1 0 0
            1 0 0 1 1
            1 1 0 1 1
            1 0 1 0 0
            1 1 1 1 0
            1 0 0 0 1
            1 1 0 0 1
            1 0 1 1 0
            1 1 1 0 1
            1 0 0 1 0
            1 1 0 1 0
            1 0 1 0 1];

%% frequency filter

exponents = repmat([4 3 2 1],16,1);

exp_filt = all_seq(:,1:4).*(alpha.^exponents);

exp_filt = sum(exp_filt,2)/sum(alpha.^(1:4));

exp_filt(all_seq(:,5) == 0) = 1-exp_filt(all_seq(:,5) == 0);

%% alternation/repetition filter

all_seq = 1-abs(diff(all_seq,1,2));

exponents = repmat([3 2 1],16,1);

exp_filt_ar = all_seq(:,1:3).*(alpha.^exponents);

exp_filt_ar = sum(exp_filt_ar,2)/sum(alpha.^(1:3));

exp_filt_ar(all_seq(:,4) == 0) = 1-exp_filt_ar(all_seq(:,4) == 0);

%figure; create_seq_eff_plot(1-(exp_filt_ar+exp_filt));

%CAREFUL ONLY ONE FILTER HERE AT THE MOMENT
rt_prediction = b+a*(exp_filt);

least2 = sum((rt_prediction-data).^2);
    
%disp(least2);

end