%% Extract Gain and Noise per image from a EMCCD camera
%INPUT: a folder containing the summary data 
%       --> an average && a standard deviation image, from a stack of >2000 images taken:
%   1) in dark conditions
%   2) from a sample that has a range of gray values within the frame.
%
%File naming in the folder should be:
%'AVG_Gain0300.tif' -> mean tiff file of the heterogeneous signal image series at a gain setting of 300
%'STD_Gain0300.tif' -> standard deviation tiff file of the heterogeneous signal image series at a gain setting of 300
%'MDK_Gain0300.tif' -> mean tiff file of the dark image series at a gain setting of 300
%'SDK_Gain0300.tif' -> standard deviation tiff file of the dark image series at a gain setting of 300
%
%OUTPUT: a results table that will sum up measured gain and read-out noise
%for the given set gain.
%%
close all
clear all
clc
%%
pathname=uigetdir;
pathname=[pathname '/'];
cd(pathname)
dd=dir([pathname 'AVG*']);

for i=1:size(dd,1)
    filename=dd(i).name;

    im=tiffread2(filename);
    st=tiffread2(['STD' filename(4:end)]);
    OFS=tiffread2(['MDK' filename(4:end)]); Doffset(i)=mean(mean(OFS.data));
    DNOi=tiffread2(['SDK' filename(4:end)]); Rnoise(i)=mean(mean(DNOi.data));
    SETgain(i)=str2num(filename(9:end-4));
    
    meanIM(i,:,:)=double(im.data)-Doffset(i);
    varIM(i,:,:)=double(st.data).^2;
end
clear im st OFS DNOi filename
%%
Lim=size(meanIM,3);
for i=1:length(SETgain)
        
        x=reshape(meanIM(i,:,:),[Lim^2,1]);
        y=reshape(varIM(i,:,:),[Lim^2,1]);

    P = polyfit(x,y,1);
    yfit = P(1)*x+P(2);
    
    res2=sqrt((y-yfit).^2)./yfit;%normalized residuals
    
figure (1), drawnow
plot(x, y, 'bo')
hold on;
plot(x,yfit,'k-.');
hold off
pause

    CHI2(i)=sum(res2);
    Mgain(i)=P(1);
    Frnoise(i)=sqrt(P(2))/P(1);
    Mrnoise(i)=Rnoise(i)/Mgain(i);
    
clear P yfit res2 x y
end

figure (2)
set(gcf, 'Position',  [730, 55, 950, 900])
yyaxis left
plot(SETgain, Mgain, 'bo-')
ylabel('Measured Gain');
yyaxis right
semilogy(SETgain,Mrnoise,'ro-.');
title('Summary Data from Mean Variance Curves');
xlabel('Micromanager Set Gain'); ylabel('Readnoise (photo-electrons');

save([pathname 'CalibrationFile.mat'])
%%