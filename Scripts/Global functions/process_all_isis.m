function [data] = process_all_isis(n_trials,n_blocks,n_back)

data = struct;

isis = dir; isis = isis(3:end);

for i = 1:length(isis)
    
    cd(isis(i).name);
    
    join_data;
    
    [data_isi] = process_2AFC_RTdata(n_trials,n_blocks,n_back); %#ok<NASGU>
    
    eval(['data.isi',isis(i).name,' = data_isi;']);
    
    cd ..
    
end