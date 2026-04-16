% remove outliers in photodiode peak detection
function [LOCS,PKS] = removePHOToutliers(LOCS, PKS, sd)

%remove peak outliers beyond a certain number of sd
LOCS = LOCS(abs(normalize(PKS)) < sd); PKS = PKS(abs(normalize(PKS)) < sd);
