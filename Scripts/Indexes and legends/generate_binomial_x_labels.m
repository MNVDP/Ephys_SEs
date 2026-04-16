clear all

binomial_x_labels = zeros(5,16);

for i = 1:length(binomial_x_labels)
   aux = dec2bin(i-1,5);
   binomial_x_labels(:,i) = [str2double(aux(1)); str2double(aux(2)); str2double(aux(3)); str2double(aux(4)); str2double(aux(5))]; 
end

order = [31 16 24 23 28 19 27 20 30 17 25 22 29 18 26 21]; order = 32-order;

binomial_x_labels = binomial_x_labels(:,order);

binomial_x_labels(binomial_x_labels == 0) = 'A'; binomial_x_labels(binomial_x_labels == 1) = 'B';

binomial_x_labels = num2cell(binomial_x_labels,1);

for i = 1:16
    binomial_x_labels{i} = char(binomial_x_labels{i});
end

save('binomial_x_labels','binomial_x_labels');