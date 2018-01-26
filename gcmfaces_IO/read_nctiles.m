function [fld]=read_nctiles(fileName,fldName,varargin);
%usage: fld=read_nctiles(fileName);                reads full field using fileName as field name
%usage: fld=read_nctiles(fileName,fldName);        reads full field (all depths, all times)
%usage: fld=read_nctiles(fileName,fldName,tt);     reads 3D or 2D field, at time index tt (all depths)
%usage: fld=read_nctiles(fileName,fldName,tt,kk);  reads 3D field, at depth index(es) kk, at time index tt 

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

global nctiles;

test1=isempty(nctiles);
test2=0;
if ~test1; 
  tmp1=dir([fileName '*']);
  test2=(length(tmp1)~=length(nctiles.no));
end;

if test1||test2;
  %build map of tile indices
  if (length(dir([fileName '*']))==mygrid.nFaces);
    nctiles.map=NaN*mygrid.XC; 
    for ff=1:mygrid.nFaces; nctiles.map{ff}(:)=ff; end;
  else;
    fileIn=sprintf('%s.%04d.nc',fileName,1);
    nc=netcdf_open(fileIn,0);
    vv = netcdf_inqVarID(nc,fldName);
    [varname,xtype,dimids,natts]=netcdf_inqVar(nc,vv);
    tileSize=zeros(1,2);
    [tmp,tileSize(1)] = netcdf_inqDim(nc,dimids(1));
    [tmp,tileSize(2)] = netcdf_inqDim(nc,dimids(2));
    netcdf_close(nc);
    nctiles.map=gcmfaces_loc_tile(tileSize(1),tileSize(2));
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
nc=netcdf_open(fileIn,0);

vv = netcdf_inqVarID(nc,fldName);
[varname,xtype,dimids,natts]=netcdf_inqVar(nc,vv);

[dimname,siz(1)] = netcdf_inqDim(nc,dimids(1));
[dimname,siz(2)] = netcdf_inqDim(nc,dimids(2));
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
  [dimname,nt] = netcdf_inqDim(nc,dimids(end));
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
fldTile=netcdf_getVar(nc,vv,start,count);
fldTile=squeeze(fldTile);
netcdf_close(nc);

%initialize fld (full gcmfaces object)
if ff==1;
  siz=[1 1 size(fldTile,3) size(fldTile,4)];
  fld=NaN*repmat(mygrid.XC,siz);
end;

%place tile in fld
fld{nctiles.f{ff}}(nctiles.i{ff},nctiles.j{ff},:,:)=fldTile;

end;%for ff=1:mygrid.nFaces;



