% find the factors found with factor analysis to SLRP and LRPR

clear; close all;

global rt_prediction

%sload cho_jones_data

load psignifit_fit_lines_data.mat
    
%% 
for i = 1:1

%% fit least squares

        data = seq_eff;

        options = optimset('Algorithm','interior-point','FinDiffType','central');

        %paramters: a,b,w,niu1,nu2,omega1,omega2
        [x,min] = fmincon(@(x) least_squares_exp_filters(x(1),x(2),x(3),data),[0 1 0.5],[],[],[],[],[-inf  -inf 0],[inf inf 1],[],options);
        
%%

        rsquared = 1-min/sum((data-mean(data)).^2);

        create_seq_eff_plot(data,rt_prediction,'font','times','labeltype','lr','errors',ci);
        
        line(get(gca,'xlim'),[0 0],'linestyle','-.','color','k');

        ylabel('PSE','fontsize',14,'fontweight','bold'); 
        
%         fit_results.subjects(s).b = x(1); 
%         fit_results.subjects(s).w1  = x(2);
%         fit_results.subjects(s).w2  = x(3);
%         fit_results.subjects(s).best_fit = rt_prediction; 

%         cd(rsis{rsi});
%          
%        printpdf(gcf,['subject',num2str(s),rsis{rsi}]);
% %        printpdf(gcf,'fit_slrp_lrpr_4back_jentzsch.pdf');
         printpdf(gcf,'fit_exp_filt_pse_data.pdf');
%     
%         cd ..
         
    %     close all

end%end each rsi

%save('fit_results_linear_combination_slrp_lrpr','fit_results');

%% tile figures in nice and tidy pdf

% system(['pdfjam --nup 2x1 fit_exp_filt_lrpr.pdf fit_exp_filt_ar_slrp.pdf --outfile filter_fits.pdf']);
% 
% system('pdfcrop filter_fits.pdf filter_fits.pdf');

% figure; create_seq_eff_plot(1-(exp_filt_ar+exp_filt));