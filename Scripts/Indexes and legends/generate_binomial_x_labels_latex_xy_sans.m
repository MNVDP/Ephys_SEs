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
    
binomial_x_labels = all_seq'; 

binomial_x_labels(binomial_x_labels == 0) = 'Y'; binomial_x_labels(binomial_x_labels == 1) = 'X';

binomial_x_labels = num2cell(binomial_x_labels,1);

str_normal = '\sffamily '; str_bold = '\bfseries\sffamily ';

for i = 1:16
    
    aux = [repmat(str_normal,4,1) binomial_x_labels{i}(1:4,:)];
    
    aux(5,1:length(str_bold)) = str_bold; aux(5,end+1) = binomial_x_labels{i}(5);
     
    binomial_x_labels{i} = aux;
    
end

binomial_x_labels_latex = binomial_x_labels;

save('binomial_x_labels_latex_x_y_sans','binomial_x_labels_latex');