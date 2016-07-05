function [fldDIV]=calc_UV_conv(fldU,fldV,varargin);
%object:    compute flow field convergent part (i.e. minus the divergence)
%inputs:    fldU and fldV are transport or velocity fields
%optional:  list_factors is the list of factors that need to 
%               be applied to fldU,fldV. By default it is empty (i.e. {}).
%               The most complete list would be {'dh','dz','hfac'}.
%output:    fldDIV is the convergence (integrated, not averaged, over grid cell area)
%
%notes:     fldU,fldV  that may be
%  either       [A] a 3D vector field
%  or           [B] a 2D vector field
%  
%  in case [A], layer thicknesses = mygrid.DRF; in case [B] layer thickness = 1
%  in any case, the global variable mygrid is supposed to be available

global mygrid;

%initialize output:
n3=max(size(fldU.f1,3),1); n4=max(size(fldV.f1,4),1);

%prepare fldU/fldV:
fldU(isnan(fldU))=0; fldV(isnan(fldV))=0;

%if nargin==3; list_factors=varargin; else; list_factors={'dh','dz','hfac'}; end;
if nargin==3; list_factors=varargin{1}; else; list_factors={}; end;

dxg=mk3D(mygrid.DXG,fldU); dyg=mk3D(mygrid.DYG,fldU); 
if size(fldU.f1,3)==length(mygrid.DRF); drf=mk3D(mygrid.DRF,fldU);
elseif size(fldU.f1,3)==1; drf=fldU; drf(:)=1;
else; error('error in calc_UV_conv: non supported field size\n');
end;
facW=drf; facW(:)=1; facS=facW;
for ii=1:length(list_factors); 
  tmp1=list_factors{ii}; 
  if strcmp(tmp1,'dh'); facW=facW.*dyg; facS=facS.*dxg; 
  elseif strcmp(tmp1,'dz'); facW=facW.*drf; facS=facS.*drf;
  elseif strcmp(tmp1,'hfac'); facW=facW.*mygrid.hFacW; facS=facS.*mygrid.hFacS;
  elseif isempty(tmp1); 1;
  else; fprintf('error in calc_UV_conv: non supported factor\n'); return;
  end;
end; 

for k4=1:n4;
fldU(:,:,:,k4)=fldU(:,:,:,k4).*facW;
fldV(:,:,:,k4)=fldV(:,:,:,k4).*facS;
end;

[FLDU,FLDV]=exch_UV(fldU,fldV);
FLDU(isnan(FLDU))=0; FLDV(isnan(FLDV))=0;

fldDIV=fldU;
for iFace=1:fldDIV.nFaces; 
fldDIV{iFace}=FLDU{iFace}(1:end-1,:,:,:)-FLDU{iFace}(2:end,:,:,:)+...
              FLDV{iFace}(:,1:end-1,:,:)-FLDV{iFace}(:,2:end,:,:);
end;


