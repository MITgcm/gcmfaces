function [fldOut,varargout]=gcmfaces_map_2d(lon,lat,fldIn,nExtrap,wRepeat);
%object:    use bin average to remap ONE lat-lon grid FIELD to a gcmfaces grid
%input:     lon,lat are the lat-lon grid, or vectors
%           fldIn is the gcmfaces field to be interpolated to lon,lat
%optional:  nExtrap (0 by default) is the number of points to extrapolate ocean field (into 
%               the land mask before interpolation to the lat-lon grid.
%           wRepeat (2 degrees by default) is the width of repeats at
%               lat-lon global domain edges (needed to avoid missing values)
%output:    fldOut is the interpolated file
%optional:  lon,lat corresponding with fldOut
%assumption : fldIn is nan-masked

gcmfaces_global;

if isempty(lon); lon=[-180:0.5:180]; lat=[-90:0.5:90]; end;
if size(lon,1)==1|size(lon,2)==1; [lat,lon]=meshgrid(lat,lon); end;
if isempty(whos('nExtrap')); nExtrap=0; end;
if isempty(whos('wRepeat')); wRepeat=2; end;

%1) extrapolate if needed
if nExtrap>0;
    mskExtrap=~isnan(fldIn);
    for ii=1:nExtrap;
        mskExtrap=exch_T_N(mskExtrap);
        for iF=1:mskExtrap.nFaces;
            tmp1=mskExtrap{iF}; tmp1(isnan(tmp1))=0;
            tmp2=tmp1(2:end-1,2:end-1)+tmp1(1:end-2,2:end-1)+tmp1(3:end,2:end-1)+tmp1(2:end-1,1:end-2)+tmp1(2:end-1,3:end);
            tmp2(tmp2~=0)=1; mskExtrap{iF}=tmp2;
        end;
    end;
    mskExtrap(find(mskExtrap==0))=NaN;
    %
    fldIn=diffsmooth2D_extrap_inv(fldIn,mskExtrap);
end;

%2) extract vector of ocean points
x=convert2vector(mygrid.XC);
y=convert2vector(mygrid.YC);
v=convert2vector(fldIn);
% ii=find(~isnan(v));
ii=find(~isnan(x));
x=x(ii); y=y(ii); v=v(ii);

%3) add points at lat-lon global domain edges
ii=find(y>90-wRepeat); x=[x;x(ii)]; y=[y;180-y(ii)]; v=[v;v(ii)];
ii=find(y<-90+wRepeat); x=[x;x(ii)]; y=[y;-180-y(ii)]; v=[v;v(ii)];
ii=find(x>180-wRepeat&x<180); x=[x;x(ii)-360]; y=[y;y(ii)]; v=[v;v(ii)];
ii=find(x<-180+wRepeat&x>-180); x=[x;x(ii)+360]; y=[y;y(ii)]; v=[v;v(ii)];

%4) generate the interpolant
F = TriScatteredInterp(x,y,v);

%5) target grid
fldOut = F(lon,lat);

%6) optional outputs:
if nargout>1; varargout={lon,lat}; end;


