function [fldOut,X,Y,weightOut]=calc_mermean_T(fldIn,method,fldType);
% CALC_MERMEAN_T(budgIn,method,fldType)
%    computes meridional average of fldIn (or its fields recursively).
%
%    If method is 1 (default) then mskCedge (from mygrid.LONS_MASKS) 
%    and volume elements used; if method is 2 then mskCedge and surface 
%    elements are used; if method is -1 or -2 then mskC is used (from mygrid) 
%    instead of mskCedge to define the averaging footpring.
%    
%    If fldType is 'intensive' (default) then fldIn is mutliplied by 
%    RAC (method=2 or -2) or RAC.*hFacC*DRF (method=1 or -1).

global mygrid;

if ~isfield(mygrid,'LONS_MASKS');
    error('please execute gcmfaces_lines_zonal to define mygrid.LONS_MASKS');
end;

if isempty(who('fldType')); fldType='intensive'; end;
if isempty(who('method')); method=1; end;

if isa(fldIn,'struct');
  list0=fieldnames(fldIn);
  fldOut=[];
  for vv=1:length(list0);
    tmp1=getfield(fldIn,list0{vv});
    if isa(tmp1,'gcmfaces');
      [tmp2,X,Y,weightOut]=calc_mermean_T(tmp1,method,fldType);
      fldOut=setfield(fldOut,list0{vv},tmp2);
    end;
  end;
  return;
end;

%initialize output:
n3=max(size(fldIn.f1,3),1); n4=max(size(fldIn.f1,4),1);
fldOut=NaN*squeeze(zeros(length(mygrid.LONS_MASKS),n3,n4));
weightOut=NaN*squeeze(zeros(length(mygrid.LONS_MASKS),n3,n4));

%use array format to speed up computation below:
fldIn=convert2gcmfaces(fldIn);
n1=size(fldIn,1); n2=size(fldIn,2);
fldIn=reshape(fldIn,n1*n2,n3*n4);

%set rac and hFacC according to method
if abs(method)==1;
  rac=reshape(convert2gcmfaces(mygrid.RAC),n1*n2,1)*ones(1,n3*n4);
  if n3==length(mygrid.RC);
      hFacC=reshape(convert2gcmfaces(mygrid.hFacC),n1*n2,n3);
      hFacC=repmat(hFacC,[1 n4]);
      DRF=repmat(mygrid.DRF',[n1*n2 n4]);
  else;
      hFacC=reshape(convert2gcmfaces(mygrid.mskC(:,:,1)),n1*n2,1)*ones(1,n3*n4);
      hFacC(isnan(hFacC))=0;
      DRF=repmat(mygrid.DRF(1),[n1*n2 n3*n4]);
  end;
  weight=rac.*hFacC.*DRF;
else;
  weight=mygrid.mskC(:,:,1).*mygrid.RAC;
  weight=reshape(convert2gcmfaces(weight),n1*n2,1)*ones(1,n3*n4);
end;

%masked area only:
weight(isnan(fldIn))=0;
weight(isnan(weight))=0;
mask=weight; mask(weight~=0)=1;
fldIn(isnan(fldIn))=0;

ny=length(mygrid.LONS_MASKS);
for iy=1:ny;

  if method>0;    
    %get list of points that form a zonal band:
    mm=convert2gcmfaces(mygrid.LONS_MASKS(iy).mskCedge);
    mm=find(~isnan(mm)&mm~=0);
  else;
      error('method < 0 remains to be implemented');
  end;

  if strcmp(fldType,'intensive');
    tmp1=nansum(fldIn(mm,:).*weight(mm,:),1)./nansum(weight(mm,:),1);
    tmp2=nansum(weight(mm,:),1);
  else;
    tmp1=nansum(fldIn(mm,:).*mask(mm,:),1)./nansum(weight(mm,:),1);
    tmp2=nansum(weight(mm,:),1);
  end;

  %store:
  fldOut(iy,:,:)=reshape(tmp1,n3,n4);
  weightOut(iy,:,:)=reshape(tmp2,n3,n4);
    
end;

X=[]; Y=[];
if size(fldOut,2)==length(mygrid.RC);
    X=mygrid.LONS*ones(1,length(mygrid.RC));
    Y=ones(length(mygrid.LONS),1)*(mygrid.RC');
elseif size(fldOut,2)==1;
    X=mygrid.LONS;
    Y=ones(length(mygrid.LONS),1);
end;

