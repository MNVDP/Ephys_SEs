function [data_temp] = analyse_all_subjects(data,remove_forward_errors,outliers,n_back)

for i = 1:length(data)
   
    data_temp(i) = analyse_2AFC_RTdata(data(i),remove_forward_errors,outliers,n_back); %#ok<AGROW>
    
end