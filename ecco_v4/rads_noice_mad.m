function []=rads_noice_mad(choiceData,l0,L0,doTesting,doNoice);
%object : outlier (& ice if doNoice) data flagging for altimetry
%inputs : choiceData is 'topexfile','ersfile' or 'gfofile'
%         l0 is the box longitude (l0+-10 will be treated)
%         L0 is the box latitude (L0+-10 will be treated)
%         doTesting (0 by default) is a testing option
%         doNoice (0 by default) activate the flagging
%            of all ice covered points (based on nsidc)
%         

if isempty(who('doTesting')); doTesting=0; end;
if isempty(who('doNoice')); doNoice=0; end;

%directories
dirData='inputfiles/';
topexfile       = 'tj_daily_ssh_v4_r1';
ersfile         = 'en_daily_ssh_v4_r1';
gfofile         = 'g1_daily_ssh_v4_r1';
dirIce='inputfiles/';
fileIce='nsidc79_daily';
dirOutput='./';

%testing switches
if doTesting; l0=-170; L0=-80; choiceData='gfofile'; end;

%select region
gcmfaces_global;
XC=convert2gcmfaces(mygrid.XC.*mygrid.mskC(:,:,1)); XC=XC(:);
YC=convert2gcmfaces(mygrid.YC.*mygrid.mskC(:,:,1)); YC=YC(:);
ii=find(XC>=l0-10&XC<=l0+10&YC>=L0-10&YC<=L0+10);
ni=length(ii);
nt=7671;%corresponds to 1992-2012

%load data
eval(['fileData=' choiceData ';']);

allData=zeros(ni,nt);
allIce=zeros(ni,nt);
ndata=0;
for yy=1992:2012;
    fprintf(['reading ' fileData '_' num2str(yy) '\n']);
    tmp1=dir([dirData fileData '_' num2str(yy)]); tmp0=tmp1.bytes/90/1170/4;
    tmp1=read2memory([dirData fileData '_' num2str(yy)],[90*1170 tmp0]);
    allData(:,ndata+[1:tmp0])=tmp1(ii,:);
    if doNoice;
      tmp1=read2memory([dirIce fileIce '_' num2str(yy)],[90*1170 tmp0]);
      allIce(:,ndata+[1:tmp0])=tmp1(ii,:);
    end;
    ndata=ndata+tmp0;
end;
allData(allData<-999)=NaN; allData=allData/100;
allIce(allIce<-999)=NaN; allIce=allIce;
if ndata~=nt; error('nt was mispecified'); end;

%if doTesting; eval(['save ' dirOutput 'rads_noice_mad.demo.mat allData allIce ndata;']); end;
%if doTesting; eval(['load ' dirOutput 'rads_noice_mad.demo.mat allData allIce ndata;']); end;

%only keep ice free data points
noiceData=allData; noiceData(allIce>0)=NaN;
iceRejectPerc=100*(1-nansum(~isnan(noiceData(:)))/nansum(~isnan(allData(:))));

%the outliers filtering
medianData=nanmedian(noiceData,2)*ones(1,nt);%center of distribution
madData=1.4826*mad(noiceData,1,2);%width of the distribution
cutoff=4*madData*ones(1,nt);%a factor 4 corresponds to a typical cost of 16
goodData=noiceData; goodData(abs(noiceData-medianData)>cutoff)=NaN;
madRejectPerc=100*(1-nansum(~isnan(goodData(:)))/nansum(~isnan(noiceData(:))));

%output result
[iceRejectPerc madRejectPerc]
%note : original testing was done with gfofile, l0=-170; L0=-80;
%       including ice points madRejectPerc is ~ 3.9%
%       excluding ice points madRejectPerc drops to 0.33%

if ~doTesting;
eval(['save ' dirOutput fileData 'l0is' num2str(l0) 'L0is' num2str(L0) ...
      ' ii goodData madData medianData iceRejectPerc madRejectPerc choiceData l0 L0 doNoice']);
end;

%------- testing case -----%

if doTesting;

%note : original testing was done with gfofile, l0=-170; L0=-80;
%       the last point (see next line) happened to work as an example
jj=find(~isnan(madData));

%do example of mad detection of ice covered points as outliers at one grid point
kk=jj(end); xc_kk=XC(ii(kk)); yc_kk=YC(ii(kk));
all_kk=allData(kk,:);
median_kk=nanmedian(all_kk);%center of distribution
mad_kk=1.4826*mad(all_kk,1,2);%width of distribution
cutoff_kk=4*mad_kk*ones(1,nt);%a factor 4 corresponds to a typical cost of 16
good_kk=all_kk; good_kk(abs(good_kk-median_kk)>cutoff_kk)=NaN;
reject_kk=100*(1-nansum(~isnan(good_kk))/nansum(~isnan(all_kk)));

%compute the various statistics
msk=1+0*allIce; msk(isnan(allData))=NaN;
%in the testing case we dont filter out the ice points : msk(allIce>0)=NaN;
stdOut=nanstd(msk.*allData,0,2);%sample standard deviation
iqrOut=0.7413*iqr(msk.*allData,2);%intequartile range estimate of std
madOut=1.4826*mad(msk.*allData,1,2);%median absolute difference estimate of std
jj=find(~isnan(stdOut));

%plot region
if L0>60; myproj=2; elseif L0<-60; myproj=3; else; myproj=1; end;
figureL; m_map_gcmfaces(mygrid.Depth,myproj,{'myCaxis',[0 6e3]}); 
colormap('gray'); colorbar off;
m_map_gcmfaces({'plot',XC(ii),YC(ii),'m.'},myproj,{'doHold',1});
m_map_gcmfaces({'plot',xc_kk,yc_kk,'k.','MarkerSize',24},myproj,{'doHold',1});

saveas(gcf,[dirOutput 'outliers_0'],'fig');
eval(['print -djpeg90 ' dirOutput 'outliers_0.jpg']);
eval(['print -depsc ' dirOutput 'outliers_0.eps']);

%plot sensitivity of std estimates to outliers
figureL;  set(gca,'FontSize',16);
plot(stdOut(jj),'.-'); hold on; plot(madOut(jj),'r.-'); plot(iqrOut(jj),'g.-');
legend('SSTD','MAD*1.4826','IQR*0.7413'); 
xlabel('grid point index'); ylabel('estimated standard deviation');

saveas(gcf,[dirOutput 'outliers_1'],'fig');
eval(['print -djpeg90 ' dirOutput 'outliers_1.jpg']);
eval(['print -depsc ' dirOutput 'outliers_1.eps']);

%plot distributions for the overall region
figureL; 
subplot(3,1,1); set(gca,'FontSize',16);
%all data points
tmp1=allData(jj,:); hist(tmp1(:),[-1.5:0.02:1.5]);
aa=axis; aa(1:2)=[-1 1]; axis(aa); title('all data points');
%and the corresponding normal distribution
[xx,yy]=normal_distribution([-1.5:0.02:1.5],tmp1(:));
hold on; plot(xx,yy,'m','LineWidth',0.5);
%
subplot(3,1,2); set(gca,'FontSize',16);
tmp1=noiceData(jj,:); hist(tmp1(:),[-1.5:0.02:1.5]);
aa=axis; aa(1:2)=[-1 1]; axis(aa); title('ice free data points');
[xx,yy]=normal_distribution([-1.5:0.02:1.5],tmp1(:));
hold on; plot(xx,yy,'m','LineWidth',0.5);
subplot(3,1,3); set(gca,'FontSize',16);
tmp1=allData(jj,:); tmp1(~isnan(noiceData(jj,:)))=NaN; hist(tmp1(:),[-1.5:0.02:1.5]); 
aa=axis; aa(1:2)=[-1 1]; axis(aa); title('icy data points');
[xx,yy]=normal_distribution([-1.5:0.02:1.5],tmp1(:));
hold on; plot(xx,yy,'m','LineWidth',0.5);

saveas(gcf,[dirOutput 'outliers_2'],'fig');
eval(['print -djpeg90 ' dirOutput 'outliers_2.jpg']);
eval(['print -depsc ' dirOutput 'outliers_2.eps']);

figureL;
subplot(2,1,1); set(gca,'FontSize',16);
hist(all_kk,[-1.5:0.02:1.5]);
aa=axis; aa(1:2)=[-1 1]; axis(aa); title('before MAD detection');
%and the corresponding normal distribution
[xx,yy]=normal_distribution([-1.5:0.02:1.5],all_kk(:));
hold on; plot(xx,yy,'m','LineWidth',2);
subplot(2,1,2); set(gca,'FontSize',16);
hist(good_kk,[-1.5:0.02:1.5]);
aa=axis; aa(1:2)=[-1 1]; axis(aa); title('after MAD detection');
%and the corresponding normal distribution
[xx,yy]=normal_distribution([-1.5:0.02:1.5],all_kk(:)); 
hold on; plot(xx,yy,'m','LineWidth',2);

saveas(gcf,[dirOutput 'outliers_3'],'fig');
eval(['print -djpeg90 ' dirOutput 'outliers_3.jpg']);
eval(['print -depsc ' dirOutput 'outliers_3.eps']);

end;

function [xx,yy]=normal_distribution(xx,data);

dx=diff(xx); 
dx=median(dx);
%dx=unique(dx); if length(dx)>1; error('plot_normal_distribution expect regular spacing\n'); end;

mm=nanmedian(data);
ss=1.4826*mad(data,1);
nn=sum(~isnan(data));
%for testing : mm=0.2; ss=0.1; nn=100;

xx=xx+mm;%reset xx to center of distribution
yy=nn*dx/ss/sqrt(2*pi)*exp(-0.5*xx.*xx/ss/ss);%compute distribution
%for testing : sum(yy)/nn

