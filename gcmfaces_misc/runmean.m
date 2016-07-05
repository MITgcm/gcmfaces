function [fldOut]=runmean(fldIn,halfWindow,dim,varargin);
%object:    compute running mean window ('rmw') over a dimension
%input:     fldIn is the field to which the rmw will be applied
%           halfWindow is the half width of the rmw
%           dim is the dimension over which the rmw will be applied
%optional:  doCycle states whether the boundary condition is cyclic (1) or
%               not (0; default). If doCycle==0, the no. of averaged points
%               decreases from 1+2*halfWindow to halfWindow at the edges,
%               and we mask all of those edge points with NaNs.
%output:    fldOut is the resulting field
%
%notes:     - NaNs are discarded in the rmw, implying that an average is
%           computed if the rmw contains at least 1 valid point.
%           - setting halfWindow to 0 implies fldOut=fldIn.

%determine and check a couple things
fld_isa_gcmfaces=isa(fldIn,'gcmfaces');
if fld_isa_gcmfaces;
    if dim<3;
        error('for gcmfaces objects runmean excludes dim=1 or 2');
    end;
end;

if nargin==3; doCycle=0; else; doCycle=varargin{1}; end;

%switch to array format if needed
if fld_isa_gcmfaces; fldIn=convert2array(fldIn); end;

%switch dim to first dimension
sizeIn=size(fldIn); 

perm1to2=[1:length(sizeIn)]; 
perm1to2=[dim perm1to2(find(perm1to2~=dim))];
perm2to1=[[1:dim-1]+1 1 [dim+1:length(sizeIn)]]; 
sizeIn2=sizeIn(perm1to2);

fldIn=permute(fldIn,perm1to2); 

sizeCur=size(fldIn);
if ~doCycle;
    %add NaNs at both edges
    sizeCur(1)=sizeCur(1)+2*halfWindow;
    fldIn2=NaN*ones(sizeCur);
    fldIn2(halfWindow+1:end-halfWindow,:,:,:)=fldIn;
    fldIn=fldIn2; clear fldIn2;
end;

%create mask and remove NaNs:
fldMsk=~isnan(fldIn);
fldIn(isnan(fldIn))=0;
fldCnt=0*fldIn;

%apply the running mean
fldOut=zeros(sizeCur);
for tcur=-halfWindow:halfWindow
    %To have halfWindow*2 coeffs rather than halfWindow*2+1, centered to the current 
    %point, it is convenient to reduce the weight of the farthest points to 1/2.
    %This became necessary to get proper annual means, from monthly data, with halfWindow=6.
    if abs(tcur)==halfWindow; fac=1/2; else; fac=1; end;
    tmp1=circshift(fldIn,[tcur zeros(1,length(sizeCur)-1)]);
    fldOut=fldOut+fac*tmp1;
    tmp1=circshift(fldMsk,[tcur zeros(1,length(sizeCur)-1)]);
    fldCnt=fldCnt+fac*tmp1;
end

fldCnt(fldCnt<2*halfWindow)=NaN;
fldOut=fldOut./fldCnt;

if ~doCycle;
    fldOut=fldOut(halfWindow+1:end-halfWindow,:,:,:);
    %consistent with old version bug (one point offset)
    %     fldOut=fldOut(halfWindow:end-halfWindow,:,:,:);
end;

%switch dimensions order back to original order
fldOut=permute(fldOut,perm2to1);

%switch back to gcmfaces format if needed
if fld_isa_gcmfaces; fldOut=convert2array(fldOut); end;



