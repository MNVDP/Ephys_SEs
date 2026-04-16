function [data] = analyse_all_rsis(data,remove_forward_errors,outliers,n_back)

rsis = fieldnames(data);

for i = 1:length(rsis)
    
    eval(['this_rsi = data.',rsis{i},';']);
    
    %analyse each subject separately
    [data_rsi_individuals] = analyse_all_subjects(this_rsi.individual_subjects,remove_forward_errors,outliers,n_back); %#ok<NASGU>
    
    eval(['data.',rsis{i},'.individual_subjects = data_rsi_individuals;']);
    
    %analyse all subjects together
    [data_rsi_grouped] = analyse_2AFC_RTdata(this_rsi.grouped_data,remove_forward_errors,outliers,n_back); %#ok<NASGU>
    
    eval(['data.',rsis{i},'.grouped_data = data_rsi_grouped;']);
    
end