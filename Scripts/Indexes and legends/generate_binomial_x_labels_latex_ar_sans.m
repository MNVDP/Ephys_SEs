clear all

%the sequences of Cho et al in the same order but in terms of sequence elements
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
    
all_seq = 1-abs(diff(all_seq,1,2));

binomial_x_labels = all_seq';

binomial_x_labels(binomial_x_labels == 0) = 'A'; binomial_x_labels(binomial_x_labels == 1) = 'R';

binomial_x_labels = num2cell(binomial_x_labels,1);

str_normal = '\sffamily '; str_bold = '\bfseries\sffamily ';

for i = 1:16
    
    aux = [repmat(str_normal,3,1) binomial_x_labels{i}(1:3,:)];
    
    aux(4,1:length(str_bold)) = str_bold; aux(4,end+1) = binomial_x_labels{i}(4);
     
    binomial_x_labels{i} = aux;
    
end

binomial_x_labels_latex = binomial_x_labels;

save('binomial_x_labels_latex_alt_rep_sans','binomial_x_labels_latex');