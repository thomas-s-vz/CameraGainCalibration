%% Extract Gain and Noise per pixel from a sCMOS camera
%INPUT: 1)Camera serial number, 2)Imaging mode, and 3) a folder containing the summary data 
%       --> an average && a standard deviation image from a stack of >2000 
%       images taken at different mean intensities. The data should range 
%       the expected range, say from 101-5000(or more) ADUs. To obtain these
%       files please use a light source that does not fluctuate (such as
%       the halogen lamp or an LED source) or increase the camera integration
%       time. The mean gray value should be part of the last 4 digits of
%       the name. The first image should be the dark image (no signal).
%
%OUTPUT: 1)a gain image (x10000), 2)a dark image and 3)a readout noise image (x1000).
%%
close all
clear all
clc
%%
CamSerial='A16I203025';%camera serial number
CamMode='Sensitivity';%camera mode: Sensitivity, Balanced, FullWell, or HDR
pathname=uigetdir;
pathname=[pathname '/'];
cd(pathname)
dd=dir([pathname 'AVG*']);

for ii=1:size(dd,1)
    filename=dd(ii).name;
    
    if ii==1
        dark=tiffread2(filename); dark=double(dark.data);
        darknoise=tiffread2(['STD' filename(4:end)]); darknoise=double(darknoise.data);
    else
    im=tiffread2(filename);
    st=tiffread2(['STD' filename(4:end)]);
    meanIM(ii-1,:,:)=double(im.data)-dark;
    varIM(ii-1,:,:)=double(st.data).^2;
    end
    
end
%%
    NoEr=zeros(size(dark,1));
count=1;

for i=1:size(dark,1)
    for j=1:size(dark,2)
        
        x=meanIM(:,i,j);
        y=varIM(:,i,j);
        
%figure (1), clf
%axis([0 500 0 1000])
%plot(x, y, 'bo')

    P = polyfit(x,y,1);
    yfit = P(1)*x+P(2);
    
    res2=(y-yfit).^2;
    
%axis([0 500 0 1000])
%hold on;
%plot(x,yfit,'r-.');
%axis([0 500 0 1000])
%pause
    if sum(res2)>300

        for lala=1:length(res2)
            
            ind=find(res2==max(res2));
            x(ind)=[];y(ind)=[];
            
            P = polyfit(x,y,1);
            yfit = P(1)*x+P(2);
            res2=(y-yfit).^2;
        
            if sum(res2)<300
                NoEr(i,j)=lala;
                break
            end
            
            count=count+1;
if mod(count,1000)==1
figure (1), drawnow
            count
axis([0 300 0 500])
plot(x, y, 'bo')
hold on;
plot(x,yfit,'k-.');
axis([0 300 0 500])
hold off
end
%pause
        end
        
    end
    
    CHI2(i,j)=sum(res2);
    Gain(i,j)=P(1);
    Mrnoise(i,j)=sqrt(P(2))/P(1);
    
    end
end

darknoise=darknoise./Gain;

save([pathname 'CalibrationFile.mat'])
imwrite(uint16(dark), [pathname CamSerial '_' CamMode '_dark_image.tif']);
imwrite(uint16(Gain*10000), [pathname CamSerial '_' CamMode '_gain_image.tif']);
imwrite(uint16(darknoise*1000), [pathname CamSerial '_' CamMode '_noise_image.tif']);


figure(2)
    set(gcf, 'Position',  [730, 55, 950, 900])
    subplot(1,2,1)
semilogy([0:3/1000:3], histc(reshape(Gain, [size(Gain,1)*size(Gain,2) 1]), [0:3/1000:3]), 'bo')
ylabel('Number of pixels'); xlabel('Measured Gain'); title('Distribution of Gains');
    subplot(1,2,2)
semilogy([0:20/1000:20], histc(reshape(darknoise, [size(darknoise,1)*size(darknoise,2) 1]), [0:20/1000:20]), 'ro')
ylabel('Number of pixels'); xlabel('Readnoise (photo-electrons)'); title('Distribution of Readnoises');

%% Post analysis checks of highlly variable pixels
% check=find(NoEr==max(max(NoEr)));
% 
% No=2;
% j=floor(check(No)/size(dark,1))+1;
% i=single((check(No)/size(dark,1)-floor(check(No)/size(dark,1)))*size(dark,1));
% 
% 
%   x=meanIM(:,i,j);
% 	y=varIM(:,i,j);
%         
%     figure (1), clf
%     %axis([0 300 0 500])
%     plot(x, y, 'bo')
%     P = polyfit(x,y,1);
%     yfit = P(1)*x+P(2);
%     %axis([0 300 0 500])
%     hold on;
%     plot(x,yfit,'r-.');
%     %axis([0 300 0 500])
% %%
%     res2=(y-yfit).^2;
%     ind=find(res2>2*std(res2));
%     x(ind)=[];y(ind)=[];
%     
%         figure (2), clf
%     %axis([0 300 0 500])
%     plot(x, y, 'bo')
%     P = polyfit(x,y,1);
%     yfit = P(1)*x+P(2);
%     %axis([0 300 0 500])
%     hold on;
%     plot(x,yfit,'r-.');
%     %axis([0 300 0 500])
% 
%%