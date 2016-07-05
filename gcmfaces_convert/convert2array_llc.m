function [FLD]=convert2array_llc(fld);
%object:    gcmfaces to array format conversion (if gcmfaces input)
%    or:    array to gcmfaces format conversion (if array input)
%
%notes:     if array input, the gcmfaces format will be the one of mygrid.XC, so 
%           the array input must have originally been created according to convert2array

global mygrid;

if isa(fld,'gcmfaces'); do_gcmfaces2array=1; else; do_gcmfaces2array=0; end;

if do_gcmfaces2array;
   n3=max(size(fld.f1,3),1); n4=max(size(fld.f1,4),1);
   n1=size(fld.f1,1)*4; n2=size(fld.f1,2)+size(fld.f1,1);
   FLD=squeeze(zeros(n1,n2,n3,n4));
else;
   n3=max(size(fld,3),1); n4=max(size(fld,4),1);
   FLD=repmat(NaN*mygrid.XC,[1 1 n3 n4]);
end;

if do_gcmfaces2array;
   %ASSEMBLE "LATLON" FACES:
   %----------------------
   FLD0=[fld.f1(:,:,:,:);fld.f2(:,:,:,:);sym_g(fld.f4(:,:,:,:),7,0);sym_g(fld.f5(:,:,:,:),7,0)];
   %ADD POLAR CAP:
   %--------------
   pp=fld.f3(:,:,:,:); FLDp=[sym_g(pp,5,0);pp.*NaN;sym_g(pp.*NaN,7,0);sym_g(pp.*NaN,6,0)]; 
   FLD1=[FLD0 FLDp];
   %store:
   %------
   FLD(:,:,:,:)=FLD1;
else;
   n1=size(FLD.f1,1); n2=size(FLD.f1,2);
   FLD.f1(:,:,:,:)=fld(1:n1,1:n2,:,:);
   FLD.f2(:,:,:,:)=fld(n1+[1:n1],1:n2,:,:);
   FLD.f3(:,:,:,:)=sym_g(fld([1:n1],n2+1:n2+n1,:,:),7,0);
   FLD.f4(:,:,:,:)=sym_g(fld(n1*2+[1:n1],1:n2,:,:),5,0);
   FLD.f5(:,:,:,:)=sym_g(fld(n1*3+[1:n1],1:n2,:,:),5,0);
end;

