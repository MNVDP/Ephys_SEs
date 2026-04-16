clear all

nums = zeros(16,5);

for i = 1:length(nums)
   aux = dec2bin(i-1,5);
   nums(i,:) = [str2double(aux(1)) str2double(aux(2)) str2double(aux(3)) str2double(aux(4)) str2double(aux(5))]; 
end

order = [31 16 24 23 28 19 27 20 30 17 25 22 29 18 26 21]; order = 32-order;

nums = nums(order,:);

nums(nums == 0) = 'A'; nums(nums == 1) = 'B';

binomial_legend = char(nums);

binomial_legend = cellstr(binomial_legend);

save('binomial_legend','binomial_legend');