function [FLD]=calc_zonmedian_T(fld);
%object:    compute zonal median
%inputs:    fld is the field of interest
%output:    FLD is the zonal median field
%
%notes:     mygrid.LATS_MASKS is the set of quasi longitudinal lines along which
%               medians will be computed, as computed in gcmfaces_lines_zonal

global mygrid;

%initialize output:
n3=max(size(fld.f1,3),1); n4=max(size(fld.f1,4),1);
FLD=NaN*squeeze(zeros(length(mygrid.LATS_MASKS),n3,n4));

%apply mask:
nr=size(mygrid.mskC.f1,3);
if n3==nr; 
  for i4=1:n4; fld(:,:,:,i4)=fld(:,:,:,i4).*mygrid.mskC; end;
else;
  for i3=1:n3; for i4=1:n4; fld(:,:,i3,i4)=fld(:,:,i3,i4).*mygrid.mskC(:,:,1); end; end;
end;

%use array format to speed up computation below:
fld=convert2array(fld); 
n1=size(fld,1); n2=size(fld,2); 
fld=reshape(fld,n1*n2,n3*n4); 

for iy=1:length(mygrid.LATS_MASKS); 

   %get list ofpoints that form a zonal band:
   mm=convert2array(mygrid.LATS_MASKS(iy).mskCedge);
   mm=find(~isnan(mm)&mm~=0);

   %do the median along this band: 
   tmp1=nanmedian(fld(mm,:),1); 

   %store:
   FLD(iy,:,:)=reshape(tmp1,n3,n4);

end; 


