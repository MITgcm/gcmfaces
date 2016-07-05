function []=rads_noice_mad_recompose(choiceData,years,doTesting);

if isempty(who('doTesting')); doTesting=0; end;
doPlot=0;

%directories
dirMad='./';
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

%testing switches
if doTesting; years=[2009:2010]; choiceData='gfofile'; end;

gcmfaces_global;
eval(['fileData=' choiceData ';']);

reject.l0=[-170:20:170]'*ones(1,9);
reject.L0=ones(18,1)*[-80:20:80];
reject.remain=NaN*zeros(18,9,20);
reject.iceRejectPerc=NaN*zeros(18,9,20);
reject.madRejectPerc=NaN*zeros(18,9,20);

for yy=years;
  fprintf(['reading ' fileData '_' num2str(yy) '\n']);
  tmp1=dir([dirRads fileData '_' num2str(yy)]); nrec=tmp1.bytes/90/1170/4;
  if yy==1992; rec00=0; else; rec00=sum(nday(1:yy-1992)); end;
  rec0=rec00+1; rec1=rec00+nrec;
  goodData=NaN*zeros(105300,nrec);
for L0=[-80:20:80];
for l0=[-170:20:170];

%select region
XC=convert2gcmfaces(mygrid.XC.*mygrid.mskC(:,:,1)); XC=XC(:);
YC=convert2gcmfaces(mygrid.YC.*mygrid.mskC(:,:,1)); YC=YC(:);
ii=find(XC>=l0-10&XC<=l0+10&YC>=L0-10&YC<=L0+10);
ni=length(ii);

%read region
tile=load([dirMad fileData 'l0is' num2str(l0) 'L0is' num2str(L0)]);

%add to accounting at proper location
[i0,j0]=find(reject.l0==l0&reject.L0==L0); y0=yy-1991;
reject.remain(i0,j0,y0)=sum(~isnan(tile.goodData(:)));
reject.iceRejectPerc(i0,j0,y0)=tile.iceRejectPerc;
reject.madRejectPerc(i0,j0,y0)=tile.madRejectPerc;

%add to goodData at proper location
if length(ii)~=length(tile.ii); error('inconsistent size'); end;
if max(abs(ii-tile.ii))~=0; error('inconsistent size'); end;
goodData(ii,:)=tile.goodData(:,rec0:rec1);

end;
end;

goodData=goodData*100;
goodData(isnan(goodData))=-9999;

if doPlot;
fld=read2memory([dirRads fileData '_' num2str(yy)]);
fld=convert2gcmfaces(reshape(fld,[90 1170 nrec]));
FLD=convert2gcmfaces(reshape(goodData,[90 1170 nrec]));
FLD(FLD<-999)=NaN; fld(fld<-999)=NaN;
%
figureL;
msk=mygrid.mskC(:,:,1);
x=mygrid.LATS;
subplot(3,1,1);
z=calc_zonmean_T(msk.*nanstd(fld,[],3)); plot(x,z); hold on;
z=calc_zonmean_T(msk.*nanstd(FLD,[],3)); plot(x,z,'r');
subplot(3,1,2);
z=calc_zonmean_T(msk.*sum(~isnan(fld),3)); plot(x,z); hold on;
z=calc_zonmean_T(msk.*sum(~isnan(FLD),3)); plot(x,z,'r');
subplot(3,1,3);
z=calc_zonmean_T(msk.*nanstd(FLD,[],3)./nanstd(fld,[],3)); plot(x,z); hold on;
z=calc_zonmean_T(msk.*sum(~isnan(FLD),3)./sum(~isnan(fld),3)); plot(x,z,'r');
%
keyboard;
end;

fid=fopen([dirOutput fileData '_mad_' num2str(yy)],'w','b');
fwrite(fid,goodData,'float32');
fclose(fid);
end;

