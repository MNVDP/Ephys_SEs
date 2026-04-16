function create_seq_eff_plot_no_legend(RT_data,fit_data)

%for testing
%RT_data = rand(1,16); fit_data = rand(1,16);

plot(RT_data,'marker','.','markersize',15,'linewidth',2); 

if nargin >1
    hold on; plot(fit_data,'r--','marker','+','markersize',8,'linewidth',2);
end

%kill x ticks and make figure smaller
%set(gca,'xtick',[],'position',get(gca,'position')+[.05 .1 -0.1 -0.05]);

xlim([.5 16.5]);

if nargin == 2
    data_min_max = [min(min(RT_data),min(fit_data)) max(max(RT_data),max(fit_data))];
else
    data_min_max = [min(RT_data) max(RT_data)];
end

data_range = data_min_max(2)-data_min_max(1);

if data_range ~= 0
    ylim([data_min_max(1)-0.02*data_range data_min_max(2)+0.02*data_range]);
end

end