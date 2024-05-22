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
nctiles_v4r4format = 0;
nctiles_v4r3_altformat = 0;

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

flist = [];
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
    if length(dir(fileIn));
      nc=netcdf.open(fileIn,0);
    elseif length(dir(sprintf('%s_%04d.nc',fileName,1992)));
      nctiles_v4r3_altformat=1;
      flist=dir([fileName '_*.nc']);
      nc=netcdf.open(sprintf('%s_%04d.nc',fileName,1992),0);
    else;
      % For v4r4 format
       nctiles_v4r4format=1;

      % split the input string "fileName" that may contain both folder and filename
      %  to folder and filename. 
      filesep_locs=findstr(fileName,filesep);
      if(isempty(filesep_locs));
        dirtmp=['.' filesep];
        fileNametmp=fileName;
      else;
        dirtmp = fileName(1:filesep_locs(end));
        fileNametmp=fileName(filesep_locs(end)+1:end);
      end;
      % Search for a global file with all 13-tiles, e.g. ECCO-GRID.nc for grid
      flisttmp=dir(fullfile(dirtmp, ['**' filesep], [fileNametmp '.nc']));
      if ~isempty(flisttmp);
        flist{1}=fullfile(flisttmp(1).folder,flisttmp(1).name);
      else;
        % No global files found. Search for all fileNametmp*.nc files. 
        flisttmp=dir(fullfile(dirtmp, ['**' filesep], [fileNametmp '*.nc']));
        flist={};
        for ijk=1:length(flisttmp);
          flist{ijk}=fullfile(flisttmp(ijk).folder,flisttmp(ijk).name);
        end;
        flist = sort(flist);
        if isempty(flist);
          error([fileIn ' not found in the current directory']);
        end;
      end;
      nc=netcdf.open(flist{1},0);
    end;
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
if(~nctiles_v4r4format & ~nctiles_v4r3_altformat);
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
elseif (nctiles_v4r3_altformat);
% nctiles_v4r3_altformat=1
% V4r3_alt has yearly files
  ntall = 0;
  lff = 0;
  if (~isempty(flist));
    lff = length(flist);
  end;
  
  if ~isempty(tt);
    t0=tt(1);
    nt=tt(end)-tt(1)+1;
    t1=t0+nt-1;
  end;

  for fft=1:lff;
    %read one file
    fileIn=fullfile(flist(fft).folder,flist(fft).name);
    nc=netcdf.open(fileIn,0);
    vv = netcdf.inqVarID(nc,fldName);

    ntindfl=getfield(ncinfo(fileIn,'time'),'Size');
    ntoffset=ntall;
    ntall=ntall+ntindfl;
    if isempty(tt);
      t0 = 1;
      t1 = ntall;
      nt = ntall;
    end;
    if(t0>ntall);
      continue
    end;
    if(t1<=ntoffset);
      break;
    end;
    if(t0>ntoffset & t0<=ntall);
       nt0=ntoffset
    end;
    
    [varname,xtype,dimids,natts]=netcdf.inqVar(nc,vv);
    lendim=length(dimids);
    siz = [];
    for idim=1:lendim;
      [dimname,siz(idim)] = netcdf.inqDim(nc,dimids(idim));
    end;

    if length(dimids)<2 or length(dimids)>5;
      error([fileIn ' only implemented for 2d thru 5d fields']);
    elseif length(dimids)==2;
      start=[0 0];
      count=[siz(1) siz(2)];
    elseif length(dimids)==3;
      start=[0 0 0];
      count=[siz(1) siz(2) siz(3)];
    elseif length(dimids)==4;
      start=[0 0 0 0];
      count=[siz(1) siz(2) siz(3) ntindfl];
    elseif isempty(kk);
       start=[0 0 0 0 0];
       count=[siz(1) siz(2) siz(3) siz(4) ntindfl];
    else;
       start=[0 0 kk(1)-1 0 0];
       count=[siz(1) siz(2) length(kk) siz(4) ntindfl];
    end;
    ndim = length(count); 

    %initialize fldTile_all (temporary array)
    if ~exist('fldTile_all');
      fldTile_all=[];
    end;

    fldTile=netcdf.getVar(nc,vv,start,count);
    fldTile=squeeze(fldTile);
    netcdf.close(nc);

    fldTile_all=cat(ndim,fldTile_all,fldTile);
  end;%for fft=1:lff;

  % for fields having time axis
  if(ntindfl>0 & length(dimids)>=4);
      if ndim==4;
         fldTile_all=fldTile_all(:,:,:,t0-nt0:t1-nt0);
      elseif isempty(kk);
         fldTile_all=fldTile_all(:,:,:,:,t0-nt0:t1-nt0);
      else;
         fldTile_all=fldTile_all(:,:,:,:,t0-nt0:t1-nt0);
      end;
  end;

  %initialize fld (full gcmfaces object)
  if(ndim==4);
    siz=[1 1 nt];
  elseif (ndim==5);
    siz=[1 1 size(fldTile,3) nt];
  end;
  fld=NaN*repmat(mygrid.XC,siz);

  %map array to gcmfaces object
  for ff=1:length(nctiles.no);
    %place tile in fld
    if size(fldTile_all,5)>1;
      fld{nctiles.f{ff}}(nctiles.i{ff},nctiles.j{ff},:,:)=fldTile_all(:,:,:,ff,:);
    elseif size(fldTile_all,4)>1;
      fld{nctiles.f{ff}}(nctiles.i{ff},nctiles.j{ff},:)=fldTile_all(:,:,ff,:);
    else;
      fld{nctiles.f{ff}}(nctiles.i{ff},nctiles.j{ff})=fldTile_all(:,:,ff);
    end;
  end; %for ff=1:length(nctiles.no);

else;
% nctiles_v4r4format=1
% if each netCDF file contains only one-time record, 13 tiles (like v4r4). 
  lff = 0;
  if (~isempty(flist));
    lff = length(flist);
  end;
  
  if ~isempty(tt);
    t0=tt(1);
    nt=tt(end)-tt(1)+1;
    t1=t0+nt-1;
  else;
    t0 = 1;
    t1 = lff;
    nt=t1-t0+1;
  end;
  for fft=t0:t1;
    %read one file
    fileIn=flist{fft};
    nc=netcdf.open(fileIn,0);
    vv = netcdf.inqVarID(nc,fldName);
  
    if fft==t0;
      [varname,xtype,dimids,natts]=netcdf.inqVar(nc,vv);
      lendim=length(dimids);
      siz = [];

      for idim=1:lendim;
        [dimname,siz(idim)] = netcdf.inqDim(nc,dimids(idim));
      end;

      siz=[siz length(mygrid.RC)];
      if length(dimids)==2;
        start=[0 0];
        count=[siz(1) siz(2)];
      elseif length(dimids)==3;
        start=[0 0 0];
        count=[siz(1) siz(2) siz(3)];
      elseif length(dimids)==4;
        start=[0 0 0 0];
        count=[siz(1) siz(2) siz(3) 1];
      elseif isempty(kk);
         start=[0 0 0 0 0];
         count=[siz(1) siz(2) siz(3) siz(4) 1];
      else;
         start=[0 0 0 kk(1)-1 0];
         count=[siz(1) siz(2) siz(3) length(kk) 1];
      end;
      ndim = length(count); 
    end;

    fldTile=netcdf.getVar(nc,vv,start,count);

    fldTile=squeeze(fldTile);
    netcdf.close(nc);

    %initialize fld (full gcmfaces object)
    if fft==t0;
      if size(fldTile,4)>1;
        siz=[1 1 size(fldTile,4) nt];
      else;
        siz=[1 1 nt];
      end;
      fld=NaN*repmat(mygrid.XC,siz);
      fldTile_all=[];
    end;

    fldTile_all=cat(ndim,fldTile_all,fldTile);
  end;%for fft=t0:t1;

  for ff=1:length(nctiles.no);
    %place tile in fld
    if size(fldTile,4)>1;
      fld{nctiles.f{ff}}(nctiles.i{ff},nctiles.j{ff},:,:)=fldTile_all(:,:,ff,:,:);
    else;
      fld{nctiles.f{ff}}(nctiles.i{ff},nctiles.j{ff},:)=fldTile_all(:,:,ff,:);
    end;
  end; %for ff=1:length(nctiles.no);
end;
