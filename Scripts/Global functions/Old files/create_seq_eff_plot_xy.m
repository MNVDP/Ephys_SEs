%this plotting function also wraps the figure window neatly around the axes
function create_seq_eff_plot_xy(RT_data,fit_data)

%for testing
%RT_data = rand(1,16); fit_data = rand(1,16);

plot(RT_data,'marker','.','markersize',15,'linewidth',2); 

if nargin >1
    hold on; plot(fit_data,'r--','marker','+','markersize',8,'linewidth',2);
end

load binomial_x_labels_latex_x_y_sans

%kill x ticks and make figure smaller
set(gca,'xtick',[],'position',get(gca,'position')+[.05 .1 -0.1 -0.05]);

xlim([.5 16.5]);

if nargin == 2
    data_min_max = [min(min(RT_data),min(fit_data)) max(max(RT_data),max(fit_data))];
else
    data_min_max = [min(RT_data) max(RT_data)];
end

data_range = data_min_max(2)-data_min_max(1);

ylim([data_min_max(1)-0.02*data_range data_min_max(2)+0.02*data_range]);

currentYlim = get(gca,'ylim');

ylim_range = currentYlim(2)-currentYlim(1);

%make x labels as text
for i = 1:16
    text(i,currentYlim(1)-.02*ylim_range,binomial_x_labels_latex{i},'VerticalAlignment','top','HorizontalAlignment','center','fontsize',...
        16,'fontweight','bold','interpreter','latex'); %#ok<USENS>
end

% give = .001;
% 
% %make vertical lines
% if nargin >1
% 
%     for i = 1:16
%         line([i i],[currentYlim(1)+give min(RT_data(i),fit_data(i))-give],'color',[.8 .8 .8]);
%     end
% 
% else
%     
%     for i = 1:16
%         line([i i],[currentYlim(1)+give RT_data(i)-give],'color',[.8 .8 .8]);
%     end
% 
% end

    axis square
    
    set(gca,'units','centimeters'); set(gcf,'units','centimeters');  set(gca,'fontsize',14);
    
    set(gcf,'position',get(gcf,'position').*[1 1 .7 1.08]);
    
    set(gca,'position',get(gca,'position').*[.4 1.45 1 1]);

end