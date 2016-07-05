function [FLD]=calc_transports(fldU,fldV,SECTIONS_MASKS,list_factors);
%object:    compute transports through pre-defined sections
%inputs:    fldU and fldV are the fields of grid point transport
%           SECTIONS_MASKS is the set of sections along
%               which transports will integrated (SECTIONS_MASKS should 
%               have been produced by line_greatC_TUV_mask.m)
%optional:  list_factors is the list of factors that need to
%               be applied to fldU,fldV. By default it is empty (i.e. {}).
%               The most complete list would be {'dh','dz','hfac'}.
%output:    FLD is the array of transport profiles

global mygrid;

%initialize output:
n3=max(size(fldU.f1,3),1); n4=max(size(fldV.f1,4),1);
FLD=NaN*squeeze(zeros(length(SECTIONS_MASKS),n3,n4));

%prepare fldU/fldV:
fldU(isnan(fldU))=0; fldV(isnan(fldV))=0;

if isempty(who('list_factors')); list_factors={}; end;

if sum(strcmp(list_factors,'dh'))>0;
  dxg=mk3D(mygrid.DXG,fldU); dyg=mk3D(mygrid.DYG,fldU);
else;
  dxg=1; dyg=1;
end;
if sum(strcmp(list_factors,'dz'))>0;
  drf=mk3D(mygrid.DRF,fldU);
else;
  drf=1;
end;
facW=1; facS=1;
for ii=1:length(list_factors);
  tmp1=list_factors{ii};
  if strcmp(tmp1,'dh'); facW=facW.*dyg; facS=facS.*dxg;
  elseif strcmp(tmp1,'dz'); facW=facW.*drf; facS=facS.*drf;
  elseif strcmp(tmp1,'hfac'); facW=facW.*mygrid.hFacW; facS=facS.*mygrid.hFacS;
  elseif isempty(tmp1); 1;
  else; fprintf('error in calc_transports : non supported factor\n'); return;
  end;
end;

for k4=1:n4;
fldU(:,:,:,k4)=fldU(:,:,:,k4).*facW;
fldV(:,:,:,k4)=fldV(:,:,:,k4).*facS;
end;

%use array format to speed up computation below:
fldU=convert2array(fldU); fldV=convert2array(fldV);

for iy=1:length(SECTIONS_MASKS); 

   %get list ofpoints that form a zonal band:
   mskW=SECTIONS_MASKS(iy).mskWedge;
   vecW=gcmfaces_subset(mskW,fldU);
   mskS=SECTIONS_MASKS(iy).mskSedge;
   vecS=gcmfaces_subset(mskS,fldV);
    
   %store:
   FLD(iy,:)=nansum(vecW,1)+nansum(vecS,1);

end; 


