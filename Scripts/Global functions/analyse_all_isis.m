function [data] = analyse_all_isis(data,remove_forward_errors,outliers,n_back)

isis = fieldnames(data);

for i = 1:length(isis)
    
    eval(['this_isi = data.',isis{i},';']);
    
    %analyse each subject separately
    [data_isi_individuals] = analyse_all_subjects(this_isi.individual_subjects,remove_forward_errors,outliers,n_back); %#ok<NASGU>
    
    eval(['data.',isis{i},'.individual_subjects = data_isi_individuals;']);
    
    %analyse all subjects together
    [data_isi_grouped] = analyse_2AFC_RTdata(this_isi.grouped_data,remove_forward_errors,outliers,n_back); %#ok<NASGU>
    
    eval(['data.',isis{i},'.grouped_data = data_isi_grouped;']);
    
end