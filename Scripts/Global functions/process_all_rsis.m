function [data] = process_all_rsis(n_trials,n_blocks,n_back)

data = struct;

rsis = dir; rsis = rsis(3:end);

for i = 1:length(rsis)
    
    cd(rsis(i).name);
    
    join_data;
    
    [data_rsi] = process_2AFC_RTdata(n_trials,n_blocks,n_back); %#ok<NASGU>
    
    eval(['data.rsi',rsis(i).name,' = data_rsi;']);
    
    cd ..
    
end