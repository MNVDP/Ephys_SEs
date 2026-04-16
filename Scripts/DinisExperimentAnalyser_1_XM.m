%Analysis of Synapse data from Dinis experiments
%Mk 1 - Core

clear
close all

toolPath = 'D:\group_swinderen\Matthew\Scripts\toolboxes';
addpath([toolPath filesep 'basefindpeaks']);

dataPath = "D:\group_swinderen\Dinis\Output Higher frequency flies\121121\15 Hz\Analyzed_TagTrials_block16\121121_chunk_0.mat";

load(dataPath);

resampleFreq = EEG.srate;
disp(resampleFreq);
%time vector
times = EEG.times;

%Plot
% figure
% plot(normalize(EEG.PHOT.data(1,:)))
% hold on
% % plot(EEG.ARAA.data(3,:))
% plot(normalize(EEG.PHOT.data(2,:)))
% title('Normalised all signals')

%% LFP and photodiode data

lfpData = EEG.LFP1.data;
photData = EEG.PHOT.data;

%% filter photodiode data

[b,a] = butter(4,150/resampleFreq*2);

photData = filter(b,a,photData.').';
lfpData = filter(b,a,lfpData);

%% Find peaks in pohotodiode data

light_on_dark = 1;

if light_on_dark
    photData(2,:) = -photData(2,:); %#ok<*UNRCH>
else
    photData(1,:) = -photData(1,:);
end

%% nuke data beyond ridiculous sd
ridiculous_sd = 5;
photData = photData.*(abs(normalize(photData,2)) < ridiculous_sd);

%%

% WARNING: MinPeakHeight = 2 seems to work well but subject to review
[PKS_PHOT1,LOCS_PHOT1] = findpeaksbase( normalize(photData(1,:)) , 'MinPeakHeight' , 1 , 'MinPeakDistance' , 0.04*resampleFreq );
[PKS_PHOT2,LOCS_PHOT2] = findpeaksbase( normalize(photData(2,:)) , 'MinPeakHeight' , 1 , 'MinPeakDistance' , 0.04*resampleFreq );

%remove outliers
outlier_sd = 2;
[LOCS_PHOT1, PKS_PHOT1] = removePHOToutliers(LOCS_PHOT1, PKS_PHOT1, outlier_sd);
[LOCS_PHOT2, PKS_PHOT2] = removePHOToutliers(LOCS_PHOT2, PKS_PHOT2, outlier_sd);

figure
plot(normalize(photData(1,:)));
hold on
scatter(LOCS_PHOT1,PKS_PHOT1)
xlabel('Index')
title('Detected peaks in phot1')

figure
plot(normalize(photData(2,:)));
hold on
scatter(LOCS_PHOT2,PKS_PHOT2)
xlabel('Index')
title('Detected peaks in phot2')

figure
histogram(diff(sort([LOCS_PHOT1 LOCS_PHOT2]))/resampleFreq,256);
xlabel('Seconds')
title('Hist. of diff. in detected photodiode onset locs')

%% Signal average ERP
windowGeometry = floor([-0.04*resampleFreq,0.06*resampleFreq]);

%Clean LOCS
LOCS_PHOT1(LOCS_PHOT1 < abs( windowGeometry(1) )) = [];

hyperGroup = struct;

for i = 1:length(LOCS_PHOT1)
    hyperGroup.data1(:,i) = lfpData(LOCS_PHOT1(i)+windowGeometry(1) : LOCS_PHOT1(i)+windowGeometry(2) );
%     hyperGroup.coords(:,:,i) = LOCS_PHOT1(i)+windowGeometry(1) : LOCS_PHOT1(i)+windowGeometry(2);
    hyperGroup.photData1(:,i) = photData(1,LOCS_PHOT1(i)+windowGeometry(1) : LOCS_PHOT1(i)+windowGeometry(2) );
end

for i = 1:length(LOCS_PHOT2)
    hyperGroup.data2(:,i) = lfpData(LOCS_PHOT2(i)+windowGeometry(1) : LOCS_PHOT2(i)+windowGeometry(2) );
    hyperGroup.photData2(:,i) = photData(2,LOCS_PHOT2(i)+windowGeometry(1) : LOCS_PHOT2(i)+windowGeometry(2) );
end

%% remove outliers from ERPs (some have colossal peaks)

outlier_bounds = [-.025 .02];

max_erps_data1 = max(hyperGroup.data1, [], 1); min_erps_data1 = min(hyperGroup.data1, [], 1);
max_erps_data2 = max(hyperGroup.data2, [], 1); min_erps_data2 = min(hyperGroup.data2, [], 1);

hyperGroup.data1 = hyperGroup.data1(:, max_erps_data1 < outlier_bounds(2) & min_erps_data1 > outlier_bounds(1));
hyperGroup.data2 = hyperGroup.data2(:, max_erps_data2 < outlier_bounds(2) & min_erps_data2 > outlier_bounds(1));

%% average (or median) ERPs

avERP1 = mean( hyperGroup.data1 , 2 );
avERP2 = mean( hyperGroup.data2 , 2 );
avPhot1 = mean( hyperGroup.photData1 , 2 );
avPhot2 = mean( hyperGroup.photData2 , 2 );

medERP1 = median( hyperGroup.data1 , 2 );
medERP2 = median( hyperGroup.data2 , 2 );
medPhot1 = median( hyperGroup.photData1 , 2 );
medPhot2 = median( hyperGroup.photData2 , 2 );

semERP1 = std(  hyperGroup.data1 , [], 2 ) / sqrt( size(hyperGroup.data1,2) );
semERP2 = std(  hyperGroup.data2 , [], 2 ) / sqrt( size(hyperGroup.data2,2) );
semPhot1 = std(  hyperGroup.photData1 , [], 2 ) / sqrt( size(hyperGroup.photData1,2) );
semPhot2 = std(  hyperGroup.photData2 , [], 2 ) / sqrt( size(hyperGroup.photData2,2) );

%% Mean ERP and Phot

figure
plot(avERP1, 'b')
hold on
plot(avPhot1*5, 'r')
yLimit = get(gca,'YLim');
line( [-windowGeometry(1) , -windowGeometry(1) ] , [yLimit(1),yLimit(2)], 'Color', 'k', 'LineStyle', ':' )


% %ERP
% groupShadeCoordsX = [1:1:size(avERP1,2),size(avERP1,2):-1:1];
% groupShadeCoordsY = [avERP1+semERP1,flip(avERP1-semERP1)];
% fill(groupShadeCoordsX, groupShadeCoordsY, 'b') %Error shading
% alpha(0.15)
 
% %Phot
% groupShadeCoordsX = [1:1:size(avPhot1,2),size(avPhot1,2):-1:1];
% groupShadeCoordsY = [avPhot1+semPhot1,flip(avPhot1-semPhot1)]*5;
% fill(groupShadeCoordsX, groupShadeCoordsY, 'r') %Error shading
% alpha(0.15)

title('Average ERP (blue) and photodiode (red) of PHOT1')

figure
plot(avERP2, 'b')
hold on
plot(avPhot2*5, 'r')
yLimit = get(gca,'YLim');
line( [-windowGeometry(1) , -windowGeometry(1) ] , [yLimit(1),yLimit(2)], 'Color', 'k', 'LineStyle', ':' )

% %ERP
% groupShadeCoordsX = [1:1:size(avERP2,2),size(avERP2,2):-1:1];
% groupShadeCoordsY = [avERP2+semERP2,flip(avERP2-semERP2)];
% fill(groupShadeCoordsX, groupShadeCoordsY, 'b') %Error shading
% alpha(0.15)
% 
% %Phot
% groupShadeCoordsX = [1:1:size(avPhot2,2),size(avPhot2,2):-1:1];
% groupShadeCoordsY = [avPhot2+semPhot2,flip(avPhot2-semPhot2)]*5;
% fill(groupShadeCoordsX, groupShadeCoordsY, 'r') %Error shading
% alpha(0.15)

title('Average ERP (blue) and photodiode (red) of PHOT2')
 
%Onion
figure
hold on
for i = 1:size(hyperGroup.data1,3)
    plot(hyperGroup.data1(:,:,i), 'b')
end
plot(avERP1,'r');
title('All ERPS PHOT1');

%Onion
figure
hold on
for i = 1:size(hyperGroup.data2,3)
    plot(hyperGroup.data2(:,:,i), 'b')
end
plot(avERP2,'r');
title('All ERPS PHOT2');

% %Onion phot
% figure
% hold on
% for i = 1:size(hyperGroup.photData,3)
%     plot(hyperGroup.photData(:,:,i), 'r')
% end
% title('All collected phot')

