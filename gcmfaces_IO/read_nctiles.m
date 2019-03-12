function [fld]=read_nctiles(fileName,fldName,varargin);
%usage: fld=read_nctiles(fileName);                reads full field using fileName as field name
%usage: fld=read_nctiles(fileName,fldName);        reads full field (all depths, all times)
%usage: fld=read_nctiles(fileName,fldName,tt);     reads 3D or 2D field, at time index tt (all depths)
%usage: fld=read_nctiles(fileName,fldName,tt,kk);  reads 3D field, at depth index(es) kk, at time index tt 
%
%note: when using old nctiles files, the deprecated old tile ordering convention may apply
%      In such cases, user wants to set a global variable named nctiles_old_tile_order
%      to 1 so that read_nctiles reverts to the old convention. 

gcmfaces_global;
nz=length(mygrid.RC);

if nargin==1; 
  tmp1=['/' fileName];
  tmp2=strfind(tmp1,filesep);
  fldName=tmp1(tmp2(end)+1:end);
end;
if nargin>2; 
    tt=varargin{1}; 
else; 
    tt=[]; 
end;
if nargin>3; 
    kk=varargin{2}; 
    if min(kk)<1 | max(kk)>nz
        error(['kk must be an integer between 1 and ' num2str(nz)])
        return
    end
    if length(kk)>1 
        if ~isempty(find(diff(kk)~=1))
          error(['kk must be a contigous range of indices'])
          return  
        end
    end    
else; 
    kk=[]; 
end;

%A) determine map of tile indices (if not already done)

global nctiles nctiles_old_tile_order;

test1=isempty(nctiles);
test2=0;
if ~test1; 
  tmp1=dir([fileName '*']);
  test2=(length(tmp1)~=length(nctiles.no));
end;

if test1|test2;
  %unless specified otherwise by user, nctiles_old_tile_order should be set 
  %to 0 in order to follow the tile ordering convention of MITgcm/pkg/exch2:
  if isempty(nctiles_old_tile_order); nctiles_old_tile_order=0; end;
  %build map of tile indices
  if (length(dir([fileName '*']))==mygrid.nFaces);
    nctiles.map=NaN*mygrid.XC; 
    for ff=1:mygrid.nFaces; nctiles.map{ff}(:)=ff; end;
  else;
    fileIn=sprintf('%s.%04d.nc',fileName,1);
    nc=netcdf.open(fileIn,0);
    vv = netcdf.inqVarID(nc,fldName);
    [varname,xtype,dimids,natts]=netcdf.inqVar(nc,vv);
    tileSize=zeros(1,2);
    [tmp,tileSize(1)] = netcdf.inqDim(nc,dimids(1));
    [tmp,tileSize(2)] = netcdf.inqDim(nc,dimids(2));
    netcdf.close(nc);
    nctiles.map=gcmfaces_loc_tile(tileSize(1),tileSize(2));
    %if specified by user then revert to old ordering convention that was used 
    %in first generation nctile files but differs from MITgcm/pkg/exch2:
    if nctiles_old_tile_order==1; 
      for gg=1:mygrid.nFaces;
        tmp1=nctiles.map{gg}; tmp2=tmp1;
        tileCount=0; tileOrigin=min(tmp1(:))-1;
        for ii=1:size(tmp1,1)/tileSize(1);
          for jj=1:size(tmp1,2)/tileSize(2);
            tileCount=tileCount+1;
            tmp_i=[1:tileSize(1)]+tileSize(1)*(ii-1);
            tmp_j=[1:tileSize(2)]+tileSize(2)*(jj-1);
            tmp2(tmp_i,tmp_j)=tileOrigin+tileCount;
          end; 
        end;
        nctiles.map{gg}=tmp2;
      end;
    end;
  end;
  %determine tile list
  nctiles.no=unique(convert2vector(nctiles.map));
  nctiles.no=nctiles.no(~isnan(nctiles.no));
  %determine location of each tile
  for ff=1:length(nctiles.no);
  for gg=1:mygrid.nFaces;
    [tmpi,tmpj]=find(nctiles.map{gg}==ff);
    if ~isempty(tmpi);
      nctiles.f{ff}=gg;
      nctiles.i{ff}=[min(tmpi(:)):max(tmpi(:))];
      nctiles.j{ff}=[min(tmpj(:)):max(tmpj(:))];
    end;
  end;
  end;
end;

%B) the file read operation itself

for ff=1:length(nctiles.no);

%read one tile
fileIn=sprintf('%s.%04d.nc',fileName,ff);
nc=netcdf.open(fileIn,0);

vv = netcdf.inqVarID(nc,fldName);
[varname,xtype,dimids,natts]=netcdf.inqVar(nc,vv);

[dimname,siz(1)] = netcdf.inqDim(nc,dimids(1));
[dimname,siz(2)] = netcdf.inqDim(nc,dimids(2));
siz=[siz length(mygrid.RC)];

if ~isempty(tt);
  t0=tt(1)-1;
  nt=tt(end)-tt(1)+1;
  if length(dimids)==3;
    start=[0 0 t0];
    count=[siz(1) siz(2) nt];
  elseif isempty(kk);
    start=[0 0 0 t0]; 
    count=[siz(1) siz(2) siz(3) nt];
  else;
    start=[0 0 kk(1)-1 t0];
    count=[siz(1) siz(2) length(kk) nt];
  end;
else
  [dimname,nt] = netcdf.inqDim(nc,dimids(end));
  if length(dimids)==2;
    start=[0 0];
    count=[siz(1) siz(2)];
  elseif length(dimids)==3;
    start=[0 0 0];
    count=[siz(1) siz(2) nt];
  elseif isempty(kk);
     start=[0 0 0 0];
     count=[siz(1) siz(2) siz(3) nt];
  else;
    start=[0 0 kk(1)-1 0];
    count=[siz(1) siz(2) length(kk) nt];
  end;
end;
fldTile=netcdf.getVar(nc,vv,start,count);
fldTile=squeeze(fldTile);
netcdf.close(nc);

%initialize fld (full gcmfaces object)
if ff==1;
  siz=[1 1 size(fldTile,3) size(fldTile,4)];
  fld=NaN*repmat(mygrid.XC,siz);
end;

%place tile in fld
fld{nctiles.f{ff}}(nctiles.i{ff},nctiles.j{ff},:,:)=fldTile;

end;%for ff=1:mygrid.nFaces;



