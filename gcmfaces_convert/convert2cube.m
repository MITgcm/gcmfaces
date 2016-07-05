function [fld11]=convert2cube(fld00);
%convert2cube takes a 1 face object and format it as a cube object

if ~(fld00.nFaces==1&mod(size(fld00{1},1),4)==0);
  error('unsupported option');
end;

fld11=gcmfaces(6);
n1=size(fld00{1},1)/4; n2=size(fld00{1},2);
fld11{1}=fld00{1}(1:n1,:,:,:);
fld11{2}=fld00{1}(n1+1:2*n1,:,:,:);
fld11{3}=NaN*fld00{1}(1:n1,1:n1,:,:);
fld11{4}=flipdim(permute(fld00{1}(2*n1+1:3*n1,:,:,:),[2 1 3 4]),1);
fld11{5}=flipdim(permute(fld00{1}(3*n1+1:4*n1,:,:,:),[2 1 3 4]),1);
fld11{6}=NaN*fld00{1}(1:n1,1:n1,:,:);

