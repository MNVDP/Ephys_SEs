%this function centres and stretches RT data so its extremes are -1 and 1
%it is an attempt at removing scale and magnitude effects from individual participant's RT data
function [rt_data] = centre_and_stretch(rt_data)

%rt_data = zscore(rt_data);

%rt_data = rt_data-mean(rt_data);

rg = range(rt_data);

rt_data = (rt_data-min(rt_data))/rg;