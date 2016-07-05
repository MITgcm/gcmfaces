function [fld]=gcmfaces_remap_2d(lon,lat,fld,nDblRes,varargin);
%object:    use bin average to remap ONE lat-lon grid FIELD to a gcmfaces grid
%input:     lon,lat,fld are the gridded product arrays
%           nDblRes is the number of times the input field 
%               resolution should be doubled before bin average.
%optional:  mskExtrap is the mask to which to extrapolate after bin average
%               If it is not specified we do no extrapolation
%note:      nDblRes>0 is useful if the starting resolution is coarse 
%               enough that the bin average would leave many empty points.
%assumption:fld should show NaN for missing values

global mygrid;
if nargin>4; mskExtrap=varargin{1}; else; mskExtrap=[]; end;

%apply meshgrid if not already the case

%switch longitude range to 0-360 if not already the case
if ~isempty(find(lon(:,1)<0));
    ii=max(find(lon(:,1)<0));
    lon=circshift(lon,[-ii 0]);
    lon(end-ii+1:end,:)=lon(end-ii+1:end,:)+360;
    fld=circshift(fld,[-ii 0]);    
end;

%refine grid before bin average:
for ii=1:nDblRes; 
    [lon,lat,fld]=dbl_res(lon,lat,fld,ii); 
end;
%put in vector form:
tmp1=find(~isnan(fld));
lon=lon(tmp1); lat=lat(tmp1); fld=fld(tmp1);
%switch longitude range to -180+180
lon(find(lon>180))=lon(find(lon>180))-360;
%compute bin average:
fld=gcmfaces_bindata(lon,lat,fld);
%potential extrapolation:
if ~isempty(mskExtrap); fld=diffsmooth2D_extrap_inv(fld,mskExtrap); end;
%apply surface land mask:
fld=fld.*mygrid.mskC(:,:,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [lonOut,latOut,obsOut]=dbl_res(lon,lat,obs,extendNaN);
%object:    use neighbor average to double the fields resolution
%inputs:    lon,lat,fld are the gridded product arrays, with 
%               NaN for missing values in fld.
%           extendNaN states whether between a real and a NaN
%               we add a NaN (extendNaN==1) or a real (extendNaN~=1)
%outputs:   lonOut,latOut,fldOut are the x2 resolution arrays
%
%assumptions: 0-360 longitudes and a consistent ordering of arrays

%check longitude range:
if ~isempty(find(lon(:)<0))|~isempty(find(lon(:)>360)); fprintf('problem in longitude specs\n'); return; end;
%check simple ordering:
tmp1=diff(lon(:,1)); if ~isempty(find(tmp1<=0)); fprintf('problem in longitude specs\n'); return; end;

%make sure that we are >=0 and <360:
if lon(1,1)>0&lon(end,1)==360; lon=[lon(end,:)-360;lon(1:end-1,:)];
    lat=[lat(end,:);lat(1:end-1,:)]; obs=[obs(end,:);obs(1:end-1,:)]; end;
%make sure that the last point is not duplicated:
if lon(1,1)==0&lon(end,1)==360; lon=lon(1:end-1,:);
    lat=lat(1:end-1,:); obs=obs(1:end-1,:); end;

%what do we do with last longitude points:
if lon(1,1)>0&lon(end,1)<360;
    addOnePt=1; %add point at the beginning
else;
    addOnePt=2; %add point at the end
end;

for ii=1:3;
    %0) get field
    if ii==1;     tmpA=lon;
    elseif ii==2; tmpA=lat;
    elseif ii==3; tmpA=obs;
    end;
    
    %1) zonal direction:
    tmpB=nanmean2flds(tmpA(1:end-1,:),tmpA(2:end,:),extendNaN);
    tmpC=ones(size(tmpA,1)*2-1,size(tmpA,2));
    tmpC(1:2:end,:)=tmpA;
    tmpC(2:2:end-1,:)=tmpB;
    %treat zonal edge of the domain
    if addOnePt==1; %add one point at the beginning
        if ii==1; offset=-360; else; offset=0; end;
        tmpB=nanmean2flds(tmpA(1,:),offset+tmpA(end,:),extendNaN); tmpC=[tmpB;tmpC];
    end;
    if addOnePt==2; %add one point at the end
        if ii==1; offset=360; else; offset=0; end;
        tmpB=nanmean2flds(offset+tmpA(1,:),tmpA(end,:),extendNaN); tmpC=[tmpC;tmpB];
    end;
    %check that we did not go too far (should not happen)
    if ii==1; tmp1=~isempty(find(lon(:)<0))|~isempty(find(lon(:)>360));
        if tmp1; fprintf('problem in longitude interp\n'); return; end;
    end;
    
    %2) meridional direction:
    tmpB=nanmean2flds(tmpC(:,1:end-1),tmpC(:,2:end),extendNaN);
    tmpA=ones(size(tmpC,1),size(tmpC,2)*2-1);
    tmpA(:,1:2:end)=tmpC;
    tmpA(:,2:2:end-1)=tmpB;
    
    %3) store field:
    if ii==1; lonOut=tmpA;
    elseif ii==2; latOut=tmpA;
    elseif ii==3; obsOut=tmpA;
    end;    
end;

%fix potential truncation errors:
lonOut(lonOut<0)=0; lonOut(lonOut>360)=360; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [fld]=nanmean2flds(fld1,fld2,extendNaN);
%object:    compute the average of two fields, accounting for NaNs
%inputs:    fld1 and fld2 are the two fields
%           if extendNaN==1 the result is NaN if either fld1 or fld2 is NaN. 
%               Otherwise the result is real if either fld1 or fld2 is real.

if extendNaN==1;
    fld=(fld1+fld2)/2;
else;
    msk1=~isnan(fld1); fld1(isnan(fld1))=0;
    msk2=~isnan(fld2); fld2(isnan(fld2))=0;
    fld=fld1+fld2;
    msk=msk1+msk2;
    msk(msk==0)=NaN;
    fld=fld./msk;
end;

