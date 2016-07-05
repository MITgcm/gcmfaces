function [zBefore,zAfter]=rads_noice_mad_plot(choiceData);

if isempty(who('doTesting')); doTesting=0; end;
doPlot=0;

%directories
dirMad='inputfiles/'
dirRads='inputfiles/';
dirOutput='./';
topexfile       = 'tj_daily_ssh_v4_r1';
ersfile         = 'en_daily_ssh_v4_r1';
gfofile         = 'g1_daily_ssh_v4_r1';
dirIce='inputfiles/';
fileIce='nsidc79_daily';

nday=zeros(20,1);
for yy=1992:2012;
  tmp1=dir([dirRads topexfile '_' num2str(yy)]);
  nday(yy-1991)=tmp1.bytes/90/1170/4;
end;

years=[1992:2012];
dayMax=datenum(years(end)+1,1,1)-datenum(years(1),1,1);

gcmfaces_global;
eval(['fileData=' choiceData ';']);

slaBefore=zeros(90*1170,dayMax);
slaAfter=slaBefore;
for yy=years;
  fprintf(['reading ' fileData '_' num2str(yy) '\n']);
  day1=1+datenum(yy,1,1)-datenum(years(1),1,1);
  dayN=datenum(yy+1,1,1)-datenum(years(1),1,1);
  %
  fld=read2memory([dirRads fileData '_' num2str(yy)],[90*1170 1+dayN-day1]);
  fld(fld<-999)=NaN;
  slaBefore(:,day1:dayN)=fld;
  %
  fld=read2memory([dirMad fileData '_mad_' num2str(yy)],[90*1170 1+dayN-day1]);
  fld(fld<-999)=NaN;
  slaAfter(:,day1:dayN)=fld;
end;

%global+time mean stats :
cntNbs=[sum(~isnan(slaBefore(:))) sum(~isnan(slaAfter(:)))];
cntNbs(3)=100*(1-cntNbs(2)/cntNbs(1));
stdNbs=[nanstd(slaBefore(:)) nanstd(slaAfter(:))];
stdNbs(3)=100*(1-stdNbs(2)/stdNbs(1));
fid = fopen([dirMad fileData '_mad_stats.txt'],'w');
 fprintf(fid,' instr         : %s \n',fileData);
 fprintf(fid,' # samples     : %d \n',cntNbs(1));
 fprintf(fid,' %% mad reject : %3.2f \n',cntNbs(3));
fclose(fid);

%global mean stats :
stdBefore=nanstd(slaBefore,[],1);
stdAfter=nanstd(slaAfter,[],1);
cntBefore=sum(~isnan(slaBefore),1);
cntAfter=sum(~isnan(slaAfter),1);

stdBefore=runmean(stdBefore,17,2);
stdAfter=runmean(stdAfter,17,2);
cntBefore=runmean(cntBefore,17,2);
cntAfter=runmean(cntAfter,17,2);

%zonal mean stats :
msk=mygrid.mskC(:,:,1);

z=nanstd(slaBefore,[],2); z=convert2gcmfaces(reshape(z,[90 1170])); 
zBefore=z;%output
slaBeforeStd=calc_zonmean_T(msk.*z);
z=nanstd(slaAfter,[],2); z=convert2gcmfaces(reshape(z,[90 1170])); 
zAfter=z;%output
slaAfterStd=calc_zonmean_T(msk.*z);

z=sum(~isnan(slaBefore),2); z=convert2gcmfaces(reshape(z,[90 1170])); 
slaBeforeCnt=calc_zonmean_T(msk.*z);
z=sum(~isnan(slaAfter),2); z=convert2gcmfaces(reshape(z,[90 1170])); 
slaAfterCnt=calc_zonmean_T(msk.*z);

%plotting:
figureL;
%
x=mygrid.LATS;
subplot(3,2,1);
plot(x,slaBeforeStd); hold on; plot(x,slaAfterStd,'r'); axis([-90 90 0 30]);
title('std before (b) and after (r)'); ylabel('cm'); xlabel('lat');
subplot(3,2,3);
plot(x,slaBeforeCnt); hold on; plot(x,slaAfterCnt,'r'); axis([-90 90 0 1e3])
title('count before (b) and after (r)'); ylabel('# obs');  xlabel('lat'); 
subplot(3,2,5);
plot(x,100*(1-slaAfterStd./slaBeforeStd),'k'); hold on;
plot(x,100*(1-slaAfterCnt./slaBeforeCnt),'m'); axis([-90 90 0 20])
title('std (k) and count (m) reduction : 100*(1-after/before)'); ylabel('%');  xlabel('lat');
%
x=[1:dayMax];
subplot(3,2,2);
plot(x,stdBefore); hold on; plot(x,stdAfter,'r'); axis([0 8e3 0 20]);
title('std before (b) and after (r)'); ylabel('cm'); xlabel('lat');
subplot(3,2,4);
plot(x,cntBefore); hold on; plot(x,cntAfter,'r'); axis([0 8e3 0 2e4]);
title('count before (b) and after (r)'); ylabel('# obs');  xlabel('lat');
subplot(3,2,6);
plot(x,100*(1-stdAfter./stdBefore),'k'); hold on;
plot(x,100*(1-cntAfter./cntBefore),'m'); axis([0 8e3 0 20]);
title('std (k) and count (m) reduction : 100*(1-after/before)'); ylabel('%');  xlabel('lat');
%

saveas(gcf,[dirMad fileData '_mad_stats'],'fig');
eval(['print -djpeg90 ' dirMad fileData '_mad_stats.jpg']);

