function [FLD]=calc_overturn(fldU,fldV,doFlip,list_factors);
%object:    compute meridional overturning streamfunction
%inputs:    fldU and fldV are the fields of grid point transport
%optional:  doFlip (default is 1). If 1 then flip the vertical 
%               axis back and forth, hence intergrating from the 
%               'bottom'. If 0 then dont.
%           list_factors (default is {'dh','dz'})
%output:    FLD is the streamfunction
%
%notes:     mygrid.LATS_MASKS is the set of quasi longitudinal lines along which
%               transports will integrated, as computed in gcmfaces_lines_zonal
%           the result is converted to Sv, and sign is changed.

global mygrid;

if nargin<3; doFlip=1; end;
if nargin<4; list_factors={'dh','dz'}; end;

%initialize output:
n3=max(size(fldU.f1,3),1); n4=max(size(fldV.f1,4),1);
FLD=NaN*squeeze(zeros(length(mygrid.LATS_MASKS),n3+1,n4));

%prepare fldU/fldV:
fldU(isnan(fldU))=0; fldV(isnan(fldV))=0;

dxg=mk3D(mygrid.DXG,fldU); dyg=mk3D(mygrid.DYG,fldU);
if size(fldU.f1,3)==length(mygrid.DRF); drf=mk3D(mygrid.DRF,fldU); else; drf=fldU; drf(:)=1; end;
facW=drf; facW(:)=1; facS=facW;
for ii=1:length(list_factors);
  tmp1=list_factors{ii};
  if strcmp(tmp1,'dh'); facW=facW.*dyg; facS=facS.*dxg;
  elseif strcmp(tmp1,'dz'); facW=facW.*drf; facS=facS.*drf;
  elseif strcmp(tmp1,'hfac'); facW=facW.*mygrid.hFacW; facS=facS.*mygrid.hFacS;
  elseif isempty(tmp1); 1;
  else; fprintf('error in calc_overturn : non supported factor\n'); return;
  end;
end;

for k4=1:n4;
fldU(:,:,:,k4)=fldU(:,:,:,k4).*facW;
fldV(:,:,:,k4)=fldV(:,:,:,k4).*facS;
end;

%use array format to speed up computation below:
fldU=convert2array(fldU); fldV=convert2array(fldV);

for iy=1:length(mygrid.LATS_MASKS); 

   %get list ofpoints that form a zonal band:
   mskW=mygrid.LATS_MASKS(iy).mskWedge;
   vecW=gcmfaces_subset(mskW,fldU);
   mskS=mygrid.LATS_MASKS(iy).mskSedge;
   vecS=gcmfaces_subset(mskS,fldV);
   trsp=nansum(vecW,1)+nansum(vecS,1);

   %store:
   if doFlip;
     FLD(iy,1:n3,:)=flipdim(cumsum(flipdim(trsp,2),2),2);
   else;
     FLD(iy,2:n3+1,:)=cumsum(trsp,2);
   end;

   %convert to Sv and change sign:
   FLD(iy,:,:)=-1e-6*FLD(iy,:,:);

end; 

if doFlip;
  FLD(:,end,:)=0;
else;
  FLD(:,1,:)=0;
end;

