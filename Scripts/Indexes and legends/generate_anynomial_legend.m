%Basically a giant amalgamation of the global functions for generating legends and labels, dynamicised for n_back

clear all

n_back = 1;

%bfString = '\bf';
%for b = 4:n_back-1 %Note: Probs won't work with an n_back less than 4?
%    bfString(b) = ' ';
%end

nums = zeros(0.5*(2^n_back),n_back);
for i = 1:length(nums)
   aux = dec2bin(i-1,n_back);
   %nums(i,:) = [str2double(aux(1)) str2double(aux(2)) str2double(aux(3)) str2double(aux(4)) str2double(aux(5))]; 
   for axios = 1:size(aux,2)
    nums(i,axios) = str2double(aux(axios)); 
   end
end

%order = [31 16 24 23 28 19 27 20 30 17 25 22 29 18 26 21]; order = 32-order;
order = []; %Used to set a custom ordering; Must be manually set

if ~isempty(order)
    nums = nums(order,:);
end

all_seq = nums;
all_seq = 1-abs(diff(all_seq,1,2));
anynomial_x_labels = all_seq';
anynomial_x_labels(anynomial_x_labels == 0) = 'A'; anynomial_x_labels(anynomial_x_labels == 1) = 'R';
anynomial_x_labels = num2cell(anynomial_x_labels,1);
for i = 1:0.5*(2^n_back)
    %aux = char(anynomial_x_labels{i}(1:3,:));
    aux = char(anynomial_x_labels{i}(1:n_back-2,:));
    %aux(4,1:4) = '\bf '; aux(4,end+1) = binomial_x_labels{i}(4);
    %aux(n_back-1,1:n_back-1) = bfString; aux(n_back-1,end+1) = anynomial_x_labels{i}(n_back-1); %Not correct?
    aux(n_back-1,1:4) = '\bf '; aux(n_back-1,end+1) = anynomial_x_labels{i}(n_back-1);
    anynomial_x_labels{i} = aux;
end
anynomial_x_labels_latex_native = anynomial_x_labels;

numsBackup = nums;

nums(nums == 0) = 'A'; nums(nums == 1) = 'B';
anynomial_legend_native = char(nums);
anynomial_legend_native = cellstr(anynomial_legend_native);

anynomial_legend_orig_native = num2str(numsBackup);
anynomial_legend_orig_native = cellstr(anynomial_legend_orig_native);

anynomial_legend_canonical = anynomial_legend_native( seq_eff_order(n_back) );
anynomial_legend_orig_canonical = anynomial_legend_orig_native( seq_eff_order(n_back) );
anynomial_x_labels_latex_canonical = anynomial_x_labels_latex_native( seq_eff_order(n_back) );

save([num2str(n_back),'-back_legend'],'n_back',...
    'anynomial_legend_native','anynomial_legend_orig_native','anynomial_x_labels_latex_native',...
    'anynomial_legend_canonical','anynomial_legend_orig_canonical','anynomial_x_labels_latex_canonical');