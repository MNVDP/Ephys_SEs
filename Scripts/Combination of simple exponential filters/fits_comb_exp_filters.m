% find the factors found with factor analysis to SLRP and LRPR

clear all; close all;

global rt_prediction

%sload cho_jones_data

% load jentzsch_data
% load ../spechul_fly.mat
load ../all_flies_dark.mat

%% 
for i = 1:1

%% fit least squares

%         data = -LRPR;
        data = -erp_seq_eff(seq_eff_order(5)).';

        options = optimset('Algorithm','interior-point','FinDiffType','central');

        %paramters: a,b,w,niu1,nu2,omega1,omega2
        [x,min] = fmincon(@(x) least_squares_exp_filters(x(1),x(2),x(3),data),[0 1 0.5],[],[],[],[],[-inf  -inf 0],[inf inf 1],[],options);
        
%%
        create_seq_eff_plot(data,rt_prediction,'errors',semSeq(seq_eff_order(5)).');

        ylabel('ERP amplitude','fontsize',18,'fontweight','bold'); 
        
%         fit_results.subjects(s).b = x(1); 
%         fit_results.subjects(s).w1  = x(2);
%         fit_results.subjects(s).w2  = x(3);
%         fit_results.subjects(s).best_fit = rt_prediction; 

%         cd(rsis{rsi});
%          
%        printpdf(gcf,['subject',num2str(s),rsis{rsi}]);
% %        printpdf(gcf,'fit_slrp_lrpr_4back_jentzsch.pdf');
%          printpdf(gcf,'fit_exp_filt_lrpr.pdf');
%         saveas(gcf,'fit_spechul_fly.png');
         saveas(gcf,'fit_all_dark.png');
%     
%         cd ..
%         
         close all

end%end each rsi

%save('fit_results_linear_combination_slrp_lrpr','fit_results');

%% tile figures in nice and tidy pdf

% system(['pdfjam --nup 2x1 fit_exp_filt_lrpr.pdf fit_exp_filt_ar_slrp.pdf --outfile filter_fits.pdf']);
% 
% system('pdfcrop filter_fits.pdf filter_fits.pdf');

% figure; create_seq_eff_plot(1-(exp_filt_ar+exp_filt));