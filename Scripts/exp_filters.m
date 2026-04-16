%simple exponential filters

close all; clear all;

%load jentzsch_data

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

alpha = .6;

%% frequency filter

exponents = repmat([4 3 2 1],16,1);

exp_filt = all_seq(:,1:4).*(alpha.^exponents);

exp_filt = sum(exp_filt,2)/sum(alpha.^(1:4));

exp_filt(all_seq(:,5) == 0) = 1-exp_filt(all_seq(:,5) == 0);

create_seq_eff_plot(1-exp_filt,[]);

ylabel('1-p(x)','fontsize',15,'fontweight','bold');

printpdf(gcf,'exp_filt');

%auxiliary calculation for the gamma parameter of the usual (recursive)
%form of the exponential filter
gamma = alpha/sum(alpha.^(1:1000));

%% alternation/repetition filter

all_seq = 1-abs(diff(all_seq,1,2));

exponents = repmat([3 2 1],16,1);

exp_filt_ar = all_seq(:,1:3).*(alpha.^exponents);

exp_filt_ar = sum(exp_filt_ar,2)/sum(alpha.^(1:3));

exp_filt_ar(all_seq(:,4) == 0) = 1-exp_filt_ar(all_seq(:,4) == 0);

%figure; create_seq_eff_plot(SLRP,((1-exp_filt_ar)*range(SLRP)+min(SLRP)));

figure; create_seq_eff_plot(1-exp_filt_ar,[]');

ylabel('1-p(x)','fontsize',15,'fontweight','bold');
%ylabel('Onset latency (ms)','fontsize',18,'fontweight','bold');

printpdf(gcf,'exp_filt_ar');

%% combine filters into one image

% system(['pdfjam --nup 2x1 exp_filt.pdf exp_filt_ar.pdf --outfile both_filters.pdf']);
% 
% system('pdfcrop both_filters.pdf both_filters.pdf');

%figure; create_seq_eff_plot(1-(exp_filt_ar+exp_filt));