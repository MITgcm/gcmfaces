function [fld0]=convert2southern(fld00,varargin);

if fld00.nFaces==1; fld00=convert2cube(fld00); end;

n1=size(fld00{1},1);
n2=size(fld00{1},2);
n3=size(fld00{1},3);
n4=size(fld00{1},4);

%rotate the cube to bring f6 to f3 position
fld11=fld00; fld11.nFaces=6;
fld11{1}=flipdim(permute(fld00{5},[2 1 3 4]),1);
fld11{2}=flipdim(permute(fld00{4},[2 1 3 4]),1);
if ~isempty(fld00.f6);
  fld11{3}=fld00{6}; 
else; 
  fld11{3}=NaN*zeros(n1,n1,n3,n4); 
end;
fld11{4}=flipdim(permute(fld00{2},[2 1 3 4]),2);
fld11{5}=flipdim(permute(fld00{1},[2 1 3 4]),2);
if ~isempty(fld00.f3); 
  fld11{6}=fld00{3};
else;
  fld11{6}=NaN*zeros(n1,n1,n3,n4);
end;

%then call convert2arctic
[fld0]=convert2arctic(fld11,varargin{:});

