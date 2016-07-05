function []=cost_bp(dirModel,dirMat,doComp,dirTex,nameTex);
%object:	compute cost function term for grace data
%inputs:	dimodel is the model directory
%               dirMat is the directory where diagnozed .mat files will be saved
%                     -> set it to '' to use the default [dirModel 'mat/']
%		doComp is a switch (1->compute; 0->display)
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

%load grid
gcmfaces_global;
if ~isfield(mygrid,'XC'); grid_load('./GRID/',5,'compact'); end;
if ~isfield(mygrid,'LATS_MASKS'); gcmfaces_lines_zonal; end;

if isempty(dir([dirModel 'barfiles']));
  dirEcco=dirModel;
else;
  dirEcco=[dirModel 'barfiles' filesep];
end;

nameSigma='GRACE_CSR_withland_err';
if ~isempty([dirModel nameSigma]);
  dirSigma=dirModel;
else;
  error(['could not find ' nameSigma]);
end;

%read model cost output
fld_dat=rdmds2gcmfaces([dirEcco 'bpdatanom_smooth']);
fld_dif=rdmds2gcmfaces([dirEcco 'bpdifanom_smooth']);

%mask:
fld_msk=rdmds2gcmfaces([dirEcco 'bpdatanom_raw']);
fld_msk(find(fld_msk~=0))=1; 
fld_msk(find(fld_msk==0))=NaN;

fld_dif=fld_dif.*fld_msk;
fld_dat=fld_dat.*fld_msk;
fld_mod=fld_dat+fld_dif;%compute model values

%read uncertainty fields
fld_err=read2memory([dirSigma nameSigma],[90 1170]);
fld_err=convert2gcmfaces(fld_err);
fld_err(find(fld_err==0))=NaN;

%compute weight
fld_w=fld_err.^-2;

%compute cost
fld_cost=mk3D(fld_w,fld_dif).*(fld_dif.^2); 
fld_cost=nanmean(fld_cost,3);

fld_dif=nanstd(fld_dif,[],3);
fld_mod=nanstd(fld_mod,[],3);
fld_dat=nanstd(fld_dat,[],3);

if ~isdir([dirMat 'cost/']); mkdir([dirMat 'cost/']); end;
eval(['save ' dirMat '/cost/cost_bp.mat fld_err fld_dif fld_mod fld_dat fld_cost;']);

else;%display previously computed results

global mygrid;

if isdir([dirMat 'cost/']); dirMat=[dirMat 'cost/']; end;

eval(['load ' dirMat '/cost_bp.mat;']);

%figure; m_map_gcmfaces(fld_cost,0,{'myCaxis',[0:0.2:1.2 1.5:0.5:3 4:1:6 8 10]});
figure; m_map_gcmfaces(fld_dif,0,{'myCaxis',[0:0.2:1.2 1.5:0.5:3 4:1:6 8 10]});
myCaption={'modeled-observed rms -- bottom pressure (cm)'};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

figure; m_map_gcmfaces(fld_mod,0,{'myCaxis',[0:0.2:1.2 1.5:0.5:3 4:1:6 8 10]});
myCaption={'rms modeled -- bottom pressure (cm)'};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

figure; m_map_gcmfaces(fld_dat,0,{'myCaxis',[0:0.2:1.2 1.5:0.5:3 4:1:6 8 10]});
myCaption={'rms observed -- bottom pressure (cm)'};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

figure; m_map_gcmfaces(fld_cost,0,{'myCaxis',[0:0.2:1.2 1.5:0.5:3 4:1:6 8 10]});
myCaption={'Cost function'};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

end;

