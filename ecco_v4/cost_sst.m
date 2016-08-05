function []=cost_sst(dirModel,dirMat,doComp,dirTex,nameTex);
%object:        compute cost function term for sst data
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

if doComp;

%grid, params and inputs

gcmfaces_global; global myparms;
if ~isfield(mygrid,'XC'); grid_load('./GRID/',5,'compact'); end;
if ~isfield(mygrid,'LATS_MASKS'); gcmfaces_lines_zonal; end;
if isfield(myparms,'yearFirst'); yearFirst=myparms.yearFirst; yearLast=myparms.yearLast;
else; yearFirst=1992; yearLast=2011;
end;

%search for nctiles files
useNctiles=0;
dirNctiles=[dirModel 'nctiles_remotesensing/sst/'];
if ~isempty(dir(dirNctiles)); useNctiles=1; end;

nameReynolds='reynolds_oiv2_r1';
nameRemss='tmi_amsre_oisst_r1';
nameL2p='tmi_amsre_l2p_r1';

dirData=dirModel; subdirReynolds=''; subdirRemss=''; subdirL2p='';
if ~isempty(dir([dirModel 'inputfiles/' nameReynolds '*']));
  dirData=[dirModel 'inputfiles/']; subdirReynolds=''; subdirRemss=''; subdirL2p='';
end;

nameSigma='sigma_surf_0p5.bin';
dirSigma=dirModel;
if ~isempty(dir([dirModel 'inputfiles/' nameSigma]));
  dirSigma=[dirModel 'inputfiles/'];
end;

fld_err=NaN*mygrid.RAC;
file0=[dirSigma nameSigma];
if ~isempty(dir(file0)); fld_err=read_bin(file0,1,0); end;
if useNctiles; fld_err=read_nctiles([dirNctiles 'sst'],'sst_sigma'); end;
fld_w=fld_err.^-2;

nameTbar='m_sst_mon';
if ~isempty(dir([dirModel nameTbar '*']));
  dirTbar=dirModel;
else;
  dirTbar=[dirModel 'barfiles' filesep];
end;
fileModel='unknown';
file0=[dirTbar nameTbar '*data']; 
if ~isempty(dir(file0)); 
  fileModel=dir(file0);
  fileModel=fileModel.name;
end;

if ~useNctiles;
%computational loop
sst_mod=repmat(NaN*mygrid.mskC(:,:,1),[1 1 12*(yearLast-yearFirst+1)]);
sst_rey=repmat(NaN*mygrid.mskC(:,:,1),[1 1 12*(yearLast-yearFirst+1)]);
sst_remss=repmat(NaN*mygrid.mskC(:,:,1),[1 1 12*(yearLast-yearFirst+1)]);
%
for ycur=yearFirst:yearLast;
fprintf(['starting ' num2str(ycur) '\n']);
tic;
for mcur=1:12;

  mm=(ycur-yearFirst)*12+mcur;

  %load Reynolds SST
  fld_rey=NaN*mygrid.RAC;
  file0=[dirData subdirReynolds nameReynolds '_' num2str(ycur)];
  if ~isempty(dir(file0)); fld_rey=read_bin(file0,mcur,0); end;
  fld_rey(find(fld_rey==0))=NaN;
  fld_rey(find(fld_rey<-99))=NaN;
  sst_rey(:,:,mm)=fld_rey;

  %load Remss SST
  fld_remss=NaN*mygrid.RAC;
  file0=[dirData subdirRemss nameRemss '_' num2str(ycur)];
  if ~isempty(dir(file0)); fld_remss=read_bin(file0,mcur,0); end;
  fld_remss(find(fld_remss==0))=NaN;
  fld_remss(find(fld_remss<-99))=NaN;
  sst_remss(:,:,mm)=fld_remss;

  %load model SST
  fld_mod=NaN*mygrid.RAC;
  file0=[dirTbar fileModel];
  if ~isempty(dir(file0)); fld_mod=read_bin(file0,mm,0); end;
  fld_mod=fld_mod.*mygrid.mskC(:,:,1);
  sst_mod(:,:,mm)=fld_mod;
end;
toc;
end;
end;%if ~useNctiles;

if useNctiles; 
 sst_rey=read_nctiles([dirNctiles 'sst'],'sst_REYNOLDS');
 sst_mod=read_nctiles([dirNctiles 'sst'],'sst_ECCOv4r2');
 sst_remss=repmat(NaN*mygrid.mskC(:,:,1),[1 1 12*(yearLast-yearFirst+1)]);
end;

%store misfit maps
mod_m_rey=sst_mod-sst_rey;
mod_m_remss=sst_mod-sst_remss;

%comp zonal means
tic;
zm_mod=calc_zonmean_T(sst_mod);
zm_rey=calc_zonmean_T(sst_rey);
zm_remss=calc_zonmean_T(sst_remss);
zm_mod_m_rey=calc_zonmean_T(mod_m_rey);
zm_mod_m_remss=calc_zonmean_T(mod_m_remss);
toc;

%compute rms maps
rms_to_rey=sqrt(nanmean(mod_m_rey.^2,3));
rms_to_remss=sqrt(nanmean(mod_m_remss.^2,3));

if ~isdir([dirMat 'cost/']); mkdir([dirMat 'cost/']); end;
eval(['save ' dirMat '/cost/cost_sst.mat fld_err rms_* zm_*;']);

else;%display previously computed results

global mygrid;

if isdir([dirMat 'cost/']); dirMat=[dirMat 'cost/']; end;

eval(['load ' dirMat '/cost_sst.mat;']);

if ~isempty(who('fld_rms')); 
  figure; m_map_gcmfaces(fld_rms,0,{'myCaxis',[0:0.2:1.2 1.5:0.5:3 4:1:6 8 10]/2});
  myCaption={'modeled-observed rms -- sea surface temperature (K)'};
  if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
else;

  testREMSS=sum(~isnan(rms_to_remss))>0;

  figure; m_map_gcmfaces(rms_to_rey,0,{'myCaxis',[0:0.2:1.2 1.5:0.5:3 4:1:6 8 10]/2});
  myCaption={'modeled-Reynolds rms -- sea surface temperature (K)'};
  if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

  if testREMSS;
  figure; m_map_gcmfaces(rms_to_remss,0,{'myCaxis',[0:0.2:1.2 1.5:0.5:3 4:1:6 8 10]/2});
  myCaption={'modeled-REMSS rms -- sea surface temperature (K)'};
  if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
  end;

  ny=size(zm_rey,2)/12;
  [xx,yy]=meshgrid(1992+([1:ny*12]-0.5)/12,mygrid.LATS);

  figureL;
  obs=zm_rey; obsCycle=sst_cycle(obs); 
  mod=zm_rey+zm_mod_m_rey; modCycle=sst_cycle(mod);
  mis=zm_mod_m_rey; misCycle=sst_cycle(mis);
  subplot(3,1,1); pcolor(xx,yy,obs-obsCycle); shading flat; caxis([-1 1]*1); colorbar;
  set(gca,'FontSize',14); set(gca,'XTick',[]); ylabel('latitude'); 
  title('Reynolds sst anomaly');
  subplot(3,1,2); pcolor(xx,yy,mod-modCycle); shading flat; caxis([-1 1]*1); colorbar;
  set(gca,'FontSize',14); set(gca,'XTick',[]); ylabel('latitude');
  title('ECCO sst anomaly');
  subplot(3,1,3); pcolor(xx,yy,mis-misCycle); shading flat; caxis([-1 1]*1); colorbar;
  set(gca,'FontSize',14); ylabel('latitude'); title('ECCO-Reynolds sst misfit');
  myCaption={'ECCO and Reynolds zonal mean sst anomalies (K)'};
  if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

  if testREMSS;
  figureL;
  obs=zm_remss; obsCycle=sst_cycle(obs);
  mod=zm_remss+zm_mod_m_remss; modCycle=sst_cycle(mod);
  mis=zm_mod_m_remss; misCycle=sst_cycle(mis);
  subplot(3,1,1); pcolor(xx,yy,obs-obsCycle); shading flat; caxis([-1 1]*1); colorbar;
  set(gca,'FontSize',14); set(gca,'XTick',[]); ylabel('latitude');
  title('REMSS sst anomaly');
  subplot(3,1,2); pcolor(xx,yy,mod-modCycle); shading flat; caxis([-1 1]*1); colorbar;
  set(gca,'FontSize',14); set(gca,'XTick',[]); ylabel('latitude');
  title('ECCO sst anomaly');
  subplot(3,1,3); pcolor(xx,yy,mis-misCycle); shading flat; caxis([-1 1]*1); colorbar;
  set(gca,'FontSize',14); ylabel('latitude'); title('ECCO-REMSS sst misfit');
  myCaption={'ECCO and REMSS zonal mean sst anomalies (K)'};
  if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
  end;

end;

end;

function [zmCycle]=sst_cycle(zmIn);

ny=size(zmIn,2)/12;
zmCycle=NaN*zeros(179,12);
for mm=1:12;
zmCycle(:,mm)=nanmean(zmIn(:,mm:12:ny*12),2);
end;
zmCycle=repmat(zmCycle,[1 ny]);

