function [FLD]=calc_MeridionalTransport(fldU,fldV,varargin);
%object:    compute net meridional transports of e.g. heat or fresh water
%inputs:    fldU and fldV are the fields of grid point transport
%optional:  doScaleWithArea, if 1 then multiply fldU by
%               dyg.*drf and accordingly for fldV.
%               If 0 (default) then it is assumed that those factors
%               have already been included (e.g. by pkg/diagnostics).
%output:    FLD is the integrated transport vector (one point per latitude).
%
%notes:     mygrid.LATS_MASKS is the set of quasi longitudinal lines along which
%               transports will integrated, as computed in gcmfaces_lines_zonal

global mygrid;

if nargin==3; doScaleWithArea=varargin{1}; else; doScaleWithArea=0; end;

%initialize output:
n3=max(size(fldU.f1,3),1); n4=max(size(fldV.f1,4),1);
FLD=NaN*squeeze(zeros(length(mygrid.LATS_MASKS),n4));

%prepare fldU/fldV:
fldU(isnan(fldU))=0; fldV(isnan(fldV))=0;

if doScaleWithArea;
   dxg=mk3D(mygrid.DXG,fldU); dyg=mk3D(mygrid.DYG,fldU); drf=mk3D(mygrid.DRF,fldU);
   for k4=1:n4;
   fldU(:,:,:,k4)=fldU(:,:,:,k4).*dyg.*drf;
   fldV(:,:,:,k4)=fldV(:,:,:,k4).*dxg.*drf;
   end;
end;

%use array format to speed up computation below:
fldU=convert2array(fldU); fldV=convert2array(fldV);

for iy=1:length(mygrid.LATS_MASKS); 

   %get list ofpoints that form a zonal band:
   mskW=mygrid.LATS_MASKS(iy).mskWedge;
   vecW=gcmfaces_subset(mskW,fldU);
   mskS=mygrid.LATS_MASKS(iy).mskSedge;
   vecS=gcmfaces_subset(mskS,fldV);
   
   %store vertically integrated transport:
   FLD(iy,:)=nansum(nansum(vecW,1)+nansum(vecS,1),2);

end; 


