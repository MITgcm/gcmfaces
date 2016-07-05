function [FLD]=convert2array_llpc(fld);
%object:    gcmfaces to array format conversion (if gcmfaces input)
%    or:    array to gcmfaces format conversion (if array input)
%
%notes:     if array input, the gcmfaces format will be the one of mygrid.XC, so 
%           the array input must have originally been created according to convert2array

global mygrid;

if isa(fld,'gcmfaces'); do_gcmfaces2array=1; else; do_gcmfaces2array=0; end;

if do_gcmfaces2array;
   n3=max(size(fld.f1,3),1); n4=max(size(fld.f1,4),1);
   n1=size(fld.f1,1)*4; n2=size(fld.f1,2);
   FLD=squeeze(zeros(n1,n2,n3,n4));
else;
   n3=max(size(fld,3),1); n4=max(size(fld,4),1);
   FLD=NaN*mygrid.XC;
   for k3=1:n3; for k4=1:n4; for iFace=1:FLD.nFaces; 
      iF=num2str(iFace); eval(['FLD.f' iF '(:,:,k3,k4)=FLD.f' iF '(:,:,1,1);']);
   end; end; end;
end;

for k3=1:n3; for k4=1:n4;

if do_gcmfaces2array;
   %ASSEMBLE SIDE FACES:
   %----------------------
   FLD1=[fld.f1(:,:,k3,k4);fld.f2(:,:,k3,k4);sym_g(fld.f3(:,:,k3,k4),7,0);sym_g(fld.f4(:,:,k3,k4),7,0)];
   %store:
   %------
   FLD(:,:,k3,k4)=FLD1;
else;
   n1=size(FLD.f1,1); n2=size(FLD.f1,2);
   FLD.f1(:,:,k3,k4)=fld(1:n1,1:n2,k3,k4);
   FLD.f2(:,:,k3,k4)=fld(n1+[1:n1],1:n2,k3,k4);
   FLD.f3(:,:,k3,k4)=sym_g(fld(n1*2+[1:n1],1:n2,k3,k4),5,0);
   FLD.f4(:,:,k3,k4)=sym_g(fld(n1*3+[1:n1],1:n2,k3,k4),5,0);
end;

end; end;

