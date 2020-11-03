function []=extend_xx(dirIn,dirOut,ndayIn,nyearOut);
%object:	extend atmospheric controls to additional years
%inputs:	dirIn is the input directory
%               dirOut is the output directory
%               ndayIn is the control vector frecuency, in days
%		nyearOut is the extended number of years
%
%note:		we will take the time mean seasonal cycle, and transition
%		to it linearly over the last year that was already covered

gcmfaces_global;

%first copy time independent controls
listCp={'diffkr','kapgm','kapredi','salt','theta'};
for ii=1:length(listCp);
  fileIn=dir([dirIn 'ADXXfiles/xx_' listCp{ii} '.00*data']);
  copyfile([dirIn 'ADXXfiles/' fileIn.name] , [dirOut fileIn.name]);
end;

%then extend the time dependent ones
for ii=1:7;
switch ii;
case 1; xxName='atemp'; 
case 2; xxName='aqh'; 
case 3; xxName='tauu'; 
case 4; xxName='tauv'; 
case 5; xxName='lwdown'; 
case 6; xxName='swdown'; 
case 7; xxName='precip';
end;

%read model cost output
fld_xx=rdmds2gcmfaces([dirIn 'ADXXfiles/xx_' xxName '.00']);

%determine already covered time period
nrec=size(fld_xx{1},3);
nyearIn=nrec*ndayIn/365;
nrecInOneYear=round(365/ndayIn);
nrecOut=nrecInOneYear*nyearOut+1;

%determine seasonal cycle
season_xx=0*fld_xx(:,:,1:nrecInOneYear);
for tt=1:nrecInOneYear;
season_xx(:,:,tt)=mean(fld_xx(:,:,tt:nrecInOneYear:nrec),3);
end;

if nyearOut==0;
more_xx=convert2gcmfaces(season_xx);
else;
%determine transition factor (fld_xx -> season_xx)
nrec0=nrecInOneYear*(floor(nyearIn)-1);
fac=([1:nrecOut]-nrec0)/(nrec-nrec0);
fac=max(min(fac,1),0);

%build extended time series
more_xx=zeros(fld_xx(:,:,1),nrecOut);
more_xx(:,:,1:nrec0)=fld_xx(:,:,1:nrec0);
for tt=nrec0+1:nrecOut;
  ttt=mod(tt,nrecInOneYear);
  if ttt==0; ttt=nrecInOneYear; end;
  if tt<nrec; 
    more_xx(:,:,tt)=fac(tt)*season_xx(:,:,ttt)+(1-fac(tt))*fld_xx(:,:,tt);
  else; 
    more_xx(:,:,tt)=season_xx(:,:,ttt);
  end;
end;

%to check the transition:
tmp1=convert2array(fld_xx); tmp11=squeeze(mean(tmp1,1));
tmp2=convert2array(more_xx); tmp22=squeeze(mean(tmp2,1));   
more_xx=convert2gcmfaces(more_xx);
end;

%save to file
fileIn=dir([dirIn 'ADXXfiles/xx_' xxName '.00*data']);
write2file([dirOut fileIn.name],more_xx);

end;%for ii=1:6;

