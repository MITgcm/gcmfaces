function []=cost_seaicearea(dirModel,dirMat,doComp,dirTex,nameTex);
%object:        compute cost function term for sea ice data
%inputs:        dimodel is the model directory
%               dirMat is the directory where diagnozed .mat files will be saved
%                     -> set it to '' to use the default [dirModel 'mat/']
%               doComp is a switch (1->compute; 0->display)
%optional:      dirTex is the directory where tex and figures files are created
%                 (if not specified then display all results to screen instead)
%               nameTex is the tex file name (default : 'myPlots')

if isempty(dirMat); dirMat=[dirModel 'mat' filesep]; else; dirMat=[dirMat filesep]; end;
if isempty(dir(dirMat));     mkdir([dirMat]); end;

%determine if and where to create tex and figures files
dirMat=[dirMat filesep];
if isempty(who('dirTex'));
  addToTex=0;
else;
  if ~ischar(dirTex); error('mis-specified dirTex'); end;
  addToTex=1;
  if isempty(who('nameTex')); nameTex='myPlots'; end;
  fileTex=[dirTex filesep nameTex '.tex'];
end;

%grid, params and inputs
gcmfaces_global; global myparms;
if ~isfield(mygrid,'XC'); grid_load('./GRID/',5,'compact'); end;
if ~isfield(mygrid,'LATS_MASKS'); gcmfaces_lines_zonal; end;
if isfield(myparms,'yearsta'); yearsta=myparms.yearsta; yearend=myparms.yearend;
else; yearsta=1992; yearend=2011;
end;

[lonPairs,latPairs,names] = line_greatC_TUV_MASKS_core2_antarctic;
lonLims=[lonPairs(1:5,1);lonPairs(1,1)];

%integrals :
nlon=(length(lonLims)-1);
areamskN=NaN*repmat(mygrid.RAC,[1 1 nlon+1]);
areamskS=NaN*repmat(mygrid.RAC,[1 1 nlon+1]);
areamskN(:,:,1)=mygrid.RAC.*(mygrid.YC>0);
areamskS(:,:,1)=mygrid.RAC.*(mygrid.YC<0);
for kk=1:nlon;
  tmpmsk=0.*mygrid.XC;
  if lonLims(kk+1) > lonLims(kk)
    tmpmsk(find(mygrid.XC >= lonLims(kk) & mygrid.XC < lonLims(kk+1)))=1.;
  else
    tmpmsk(find(mygrid.XC >= lonLims(kk) & mygrid.XC <= 180.))=1.;
    tmpmsk(find(mygrid.XC >= -180. & mygrid.XC < lonLims(kk+1)))=1.;
  end
  areamskN(:,:,1+kk)=mygrid.RAC.*tmpmsk.*(mygrid.YC>0);
  areamskS(:,:,1+kk)=mygrid.RAC.*tmpmsk.*(mygrid.YC<0);
end;

%search for nctiles files
useNctiles=0;
dirNctiles=[dirModel 'nctiles_remotesensing/sic/'];
if ~isempty(dir(dirNctiles)); useNctiles=1; end;

if doComp;
%grid, params and inputs
fld_err=0.5*ones(90,1170); fld_err=convert2gcmfaces(fld_err);
if useNctiles; fld_err=read_nctiles([dirNctiles 'sic'],'sic_sigma'); end;
fld_w=fld_err.^-2;

dirEcco=dirModel;
if ~isempty(dir([dirModel 'barfiles']));
  dirEcco=[dirModel 'barfiles' filesep];
end;

nameData='nsidc79_monthly_';
dirData=dirModel;
if ~isempty(dir([dirModel 'inputfiles/' nameData '*']));
  dirData=[dirModel 'inputfiles/'];
end;

fileModel='unknown';
file0=[dirEcco 'm_siv4_area*data'];
if ~isempty(dir(file0)); fileModel=dir(file0); fileModel=fileModel.name; end;

nyears=yearend-yearsta+1;
nmonths=12*nyears;

if ~useNctiles;
%misfits :
fld_estim=convert2gcmfaces(NaN*ones(90,90*13,nmonths));
fld_nsidc=convert2gcmfaces(NaN*ones(90,90*13,nmonths));
fld_dif=convert2gcmfaces(NaN*ones(90,90*13,nmonths));

%computational loop :
for ycur=yearsta:yearend;
 tic;
 for mcur=1:12;
  mm=(ycur-yearsta)*12+mcur;

  fld_dat=NaN*mygrid.RAC;
  file0=[dirData nameData num2str(ycur)];
  if ~isempty(dir(file0)); fld_dat=read_bin(file0,mcur,0); end;
  fld_dat=fld_dat.*mygrid.mskC(:,:,1);%land mask
  fld_dat(find(fld_dat<-99))=NaN;%missing data
  msk=1+0*fld_dat;%combined mask

  fld_mod=NaN*mygrid.RAC;
  file0=[dirEcco fileModel];
  if ~isempty(dir(file0)); fld_mod=read_bin(file0,mm,0); end;
  fld_mod=fld_mod.*msk;%mask consistent with fld_dat

  %misfits :
  fld_estim(:,:,mm)=fld_mod;
  fld_nsidc(:,:,mm)=fld_dat;
  fld_dif(:,:,mm)=fld_mod-fld_dat;
 end;
 toc;
end;
end;%if ~useNctiles;

if useNctiles;
 fld_estim=read_nctiles([dirNctiles 'sic'],'sic_ECCOv4r2');
 fld_nsidc=read_nctiles([dirNctiles 'sic'],'sic_NSIDC');
 fld_estim(isnan(fld_nsidc))=NaN;
 fld_nsidc(isnan(fld_estim))=NaN;
 fld_dif=fld_estim-fld_nsidc;
end;

%monthly mean climatology :
climMod=reshape(fld_estim,[1 1 12 nyears]); 
climMod=nanmean(climMod,4);
climObs=reshape(fld_nsidc,[1 1 12 nyears]);
climObs=nanmean(climObs,4);

%monthly integrals :
IceAreaNorthMod=NaN*zeros(1+nlon,nmonths);
IceAreaNorthObs=NaN*zeros(1+nlon,nmonths);
IceAreaSouthMod=NaN*zeros(1+nlon,nmonths);
IceAreaSouthObs=NaN*zeros(1+nlon,nmonths);
for mm=1:nlon+1;
  tmp1=fld_estim.*repmat(areamskN(:,:,mm),[1 1 nmonths]);
  IceAreaNorthMod(mm,:)=nansum(tmp1,0);
  tmp1=fld_nsidc.*repmat(areamskN(:,:,mm),[1 1 nmonths]);
  IceAreaNorthObs(mm,:)=nansum(tmp1,0);
  %
  tmp1=fld_estim.*repmat(areamskS(:,:,mm),[1 1 nmonths]);
  IceAreaSouthMod(mm,:)=nansum(tmp1,0);
  tmp1=fld_nsidc.*repmat(areamskS(:,:,mm),[1 1 nmonths]);
  IceAreaSouthObs(mm,:)=nansum(tmp1,0);
end;

%misfits :
mis_rms=sqrt(nanmean(fld_dif.^2,3));
obs_std=nanstd(fld_nsidc,[],3);
mod_std=nanstd(fld_nsidc+fld_dif,[],3);

if ~isdir([dirMat 'cost/']); mkdir([dirMat 'cost/']); end;
eval(['save ' dirMat '/cost/cost_seaicearea.mat fld_err mis_rms obs_std mod_std IceArea* clim*;']);

else;%display previously computed results

if isdir([dirMat 'cost/']); dirMat=[dirMat 'cost/']; end;

eval(['load ' dirMat '/cost_seaicearea.mat;']);

%variance maps:
figure; m_map_gcmfaces(mis_rms,0,{'myCaxis',[0:0.1:1.]});
myCaption={'modeled-observed rms -- sea ice concentration'};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

figure; m_map_gcmfaces(obs_std,0,{'myCaxis',[0:0.1:1.]});
myCaption={'observed std -- sea ice concentration'};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

figure; m_map_gcmfaces(mod_std,0,{'myCaxis',[0:0.1:1.]});
myCaption={'modelled std -- sea ice concentration'};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

%arctic maps
figureL; 
subplot(2,2,1); m_map_gcmfaces(climMod(:,:,3),2,{'myCaxis',[0:0.1:1.]});
subplot(2,2,2); m_map_gcmfaces(climObs(:,:,3),2,{'myCaxis',[0:0.1:1.]});
subplot(2,2,3); m_map_gcmfaces(climMod(:,:,9),2,{'myCaxis',[0:0.1:1.]});
subplot(2,2,4); m_map_gcmfaces(climObs(:,:,9),2,{'myCaxis',[0:0.1:1.]});
myCaption={'ECCO (left) and NSIDC (right, gsfc bootstrap) ice concentration in March (top) and September (bottom).'};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

%southern ocean maps
figureL;
subplot(2,2,1); m_map_gcmfaces(climMod(:,:,3),3,{'myCaxis',[0:0.1:1.]});
subplot(2,2,2); m_map_gcmfaces(climObs(:,:,3),3,{'myCaxis',[0:0.1:1.]});
subplot(2,2,3); m_map_gcmfaces(climMod(:,:,9),3,{'myCaxis',[0:0.1:1.]});
subplot(2,2,4); m_map_gcmfaces(climObs(:,:,9),3,{'myCaxis',[0:0.1:1.]});
myCaption={'ECCO (left) and NSIDC (right, gsfc bootstrap) ice concentration in March (top) and September (bottom).'};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

%northern/southern integrals
ny=length(IceAreaNorthMod)/12;
yy=yearsta+[0:ny-1];

figureL;
subplot(1,2,1);
plot(yy,IceAreaNorthMod(1,3:12:end),'LineWidth',2); hold on;
plot(yy,IceAreaNorthObs(1,3:12:end),'r','LineWidth',2);
plot(yy,IceAreaNorthMod(1,9:12:end),'LineWidth',2);
plot(yy,IceAreaNorthObs(1,9:12:end),'r','LineWidth',2);
axis([yearsta yearsta+ny-1 0 20e12]);
ylabel('m^2'); title('Northern Hemisphere');
subplot(1,2,2);
plot(yy,IceAreaSouthMod(1,3:12:end),'LineWidth',2); hold on;
plot(yy,IceAreaSouthObs(1,3:12:end),'r','LineWidth',2);
plot(yy,IceAreaSouthMod(1,9:12:end),'LineWidth',2);
plot(yy,IceAreaSouthObs(1,9:12:end),'r','LineWidth',2);
axis([yearsta yearsta+ny-1 0 20e12]);
ylabel('m^2'); title('Southern Hemisphere');

myCaption={'ECCO (blue) and NSIDC (red, gsfc bootstrap) ice concentration in March and September',...
           'in Northern Hemisphere (left) and Southern Hemisphere (right)'};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

%southern basin integrals

for mm=[3 9];
  figureL;
  for ii=1:6;
    subplot(3,2,ii);
    if ii==1; iiTxt='Entire Southern Ocean';
    else; iiTxt=sprintf('%dE to %dE',lonLims(ii-1),lonLims(ii));
    end;
    plot(yy,IceAreaSouthMod(ii,mm:12:end),'LineWidth',2); hold on;
    plot(yy,IceAreaSouthObs(ii,mm:12:end),'r','LineWidth',2);
    aa=axis; aa(1:2)=[yearsta yearsta+ny-1]; axis(aa);
    ylabel('m^2'); title(iiTxt);
  end;
  if mm==3; mmTxt='March'; elseif mm==9; mmTxt='September'; else; '???'; end;
  myCaption={'ECCO (blue) and NSIDC (red, gsfc bootstrap) ice concentration in ',mmTxt,' per Southern Ocean sector'};
  if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
end;

end;


