function [dimOut]=write2nctiles(fileOut,fldIn,doCreate,varargin);
%object : write gcmfaces object to netcdf files (tiled)
%inputs : fileOut is the name of the file to be created
%         fldIn is the array to write to disk
%         doCreate is a 0/1 switch; 1 => create file ; 0 => append to file. 
%optional paramaters :
%         can be provided in the form {'name',value}
%         those that are currently active are
%               'descr' is the file description (default '').
%               'rdm' is the extended estimate description (default '').
%               'fldName' is the nc variable name for fld (default : the outside name of fldIn).
%               'longName' is the corresponding long name (default : '').
%               'units' is the unit of fld (default : '(unknown)').
%               'missval' is the missing value (default : NaN).
%               'fillval' is the fill value (default : NaN).
%               'tileNo' is a map of tile indices (default is face number)
%		'coord' is auxilliary coordinates attribute (e.g. 'lon lat dep')
%               'dimsize' is the array size associated with 'coord'
%               'xtype' is 'double' by default 
%netcdf dimensions : array dimensions are simply set to 'i1,i2,...'

gcmfaces_global;
if ~(myenv.useNativeMatlabNetcdf);
  error('only native matlab nectdf is supported in write2nctiles');
end;

doCheck=0;%set to one to print stuff to screen

fldInIsaGcmfaces=isa(fldIn,'gcmfaces');

if fldInIsaGcmfaces;
  fldInIsEmpty=isempty(fldIn{1});
else;
  fldInIsEmpty=isempty(fldIn);
end;

%set more optional paramaters to default values
descr=''; 
rdm='';
fldName=inputname(2); longName=''; 
units='(unknown)'; missval=NaN; fillval=NaN; dimIn=[];
tileNo=mygrid.XC; for ff=1:mygrid.nFaces; tileNo{ff}(:)=ff; end;
coord=''; dimsize=[]; xtype='double';

%set more optional paramaters to user defined values
for ii=1:nargin-3;
    if ~iscell(varargin{ii});
        warning('inputCheck:write2nctiles_1',...
            ['write2nctiles expects \n'...
            '         its optional parameters as cell arrays. \n'...
            '         Argument no. ' num2str(ii+1) ' was ignored \n'...
            '         Type ''help write2nctiles'' for details.']);
    elseif ~ischar(varargin{ii}{1});
        warning('inputCheck:write2nctiles_2',...
            ['write2nctiles expects \n'...
            '         its optional parameters cell arrays \n'...
            '         to start with character string. \n'...
            '         Argument no. ' num2str(ii+1) ' was ignored \n'...
            '         Type ''help write2nctiles'' for details.']);
    else;
        if strcmp(varargin{ii}{1},'descr')|...
                strcmp(varargin{ii}{1},'rdm')|...
                strcmp(varargin{ii}{1},'fldName')|...
                strcmp(varargin{ii}{1},'longName')|...
                strcmp(varargin{ii}{1},'units')|...
                strcmp(varargin{ii}{1},'missval')|...
                strcmp(varargin{ii}{1},'fillval')|...
                strcmp(varargin{ii}{1},'tileNo')|...
                strcmp(varargin{ii}{1},'coord')|...
                strcmp(varargin{ii}{1},'dimsize')|...
                strcmp(varargin{ii}{1},'xtype')|...
                strcmp(varargin{ii}{1},'dimIn');
            eval([varargin{ii}{1} '=varargin{ii}{2};']);
        else;
            warning('inputCheck:write2nctiles_3',...
                ['unknown option ''' varargin{ii}{1} ''' was ignored']);
        end;
    end;
end;

%split fldIn (if isa gcmfaces) into tiles
tileList=unique(convert2vector(tileNo)); 
tileList=tileList(~isnan(tileList));
ntile=length(tileList);
%
if fldInIsaGcmfaces&~fldInIsEmpty;
 for ff=1:ntile; 
   tmp1=[];
   for gg=1:mygrid.nFaces;
     [tmpi,tmpj]=find(tileNo{gg}==ff);
     if ~isempty(tmpi);
       tmpi=[min(tmpi(:)):max(tmpi(:))];
       tmpj=[min(tmpj(:)):max(tmpj(:))];
       tmp1=fldIn{gg}(tmpi,tmpj,:,:);
     end;
   end;
   fldTiles{ff}=tmp1;
 end;
 clear fldIn;
elseif fldInIsaGcmfaces;
 for ff=1:ntile;
   fldTiles{ff}=[];
 end;
end;

%start processing loop
for ff=1:ntile;

if fldInIsaGcmfaces;
  fldTile=fldTiles{ff};
  %reverse order of dimensions
  nn=length(size(fldTile));
  fldTile=permute(fldTile,[nn:-1:1]);
  if ntile==1; clear fldTiles; end;
else;
  fldTile=fldIn;
end;
fileTile=[fileOut sprintf('.%04d.nc',ff)];

%select dimensions of relevance:
if ~fldInIsEmpty;
  nDim=length(size(fldTile));
  dimsize=size(fldTile);
elseif ~isempty(dimsize);
  nDim=length(dimsize);
else;
  error('undertermined array size');
end;

for iDim=1:nDim;
if dimsize(iDim)~=1;
    dimlist{iDim}=['i' num2str(iDim)];
    dimName{iDim}=['array index ' num2str(iDim)];
    eval(['dimvec.i' num2str(iDim) '=[1:dimsize(iDim)];']);
end;
end;

%omit singleton dimensions:
ii=find(dimsize~=1);
dimsize=dimsize(ii);
dimlist={dimlist{ii}};
dimName={dimName{ii}};

%check : 
if doCheck;
whos fldTile
descr
fldName
longName
units
missval
fillval
dimlist
dimName
dimsize
dimvec
keyboard;
end;

%output dimension information
dimOut{ff}=dimlist;

if doCreate;
  %create netcdf file:
  %-------------------
  if prod(dimsize)*4/1e9<1.5;%use (always available) basic netcdf:
    mode='clobber';
  else;%to allow for large file:
    mode='NETCDF4';
  end;
  ncid=nccreateFile(fileTile,mode);
  nc_global=netcdf.getConstant('NC_GLOBAL');

  if ~isempty(rdm); 
    descr2=[descr ' -- ' rdm{1}];
  else;
    descr2=descr;
  end;
  ncputAtt(ncid,'','description',descr2);
  for pp=2:length(rdm);
  tmp1=char(pp+63);
  netcdf.putAtt(ncid,nc_global,tmp1,rdm{pp});
  end;
  %append readme
  pp=length(rdm)+1;
  netcdf.putAtt(ncid,nc_global,tmp1,'file created using gcmfaces_IO/write2nctiles.m');
  ncputAtt(ncid,'','date',date);
  netcdf.putAtt(ncid,nc_global,'Conventions','CF-1.6')   

  ncputAtt(ncid,'','_FillValue',fillval);
  ncputAtt(ncid,'','missing_value',missval);

  ncdefDim(ncid,'itxt',30);
  for dd=1:length(dimlist); ncdefDim(ncid,dimlist{dd},dimsize(dd)); end;

  for dd=1:length(dimlist);
    ncdefVar(ncid,dimlist{dd},'double',{dimlist{dd}});
    ncputAtt(ncid,dimlist{dd},'long_name',dimName{dd});
    ncputAtt(ncid,dimlist{dd},'units','1');
  end;
  ncclose(ncid);

  %fill in the dimensions dimensions values vectors:
  %-------------------------------------------------
  ncid=ncopen(fileTile,'write');
  for dd=1:length(dimlist);
    ncputvar(ncid,dimlist{dd},getfield(dimvec,dimlist{dd}));
  end;
  ncclose(ncid);
end;

%use dimentsion specified by user
if ~isempty(dimIn); dimlist=dimIn{ff}; end;

%define and fill field:
%----------------------
ncid=ncopen(fileTile,'write');
%
netcdf.reDef(ncid);
ncdefVar(ncid,fldName,xtype,flipdim(dimlist,2));%note the direction flip
if ~isempty(longName); ncputAtt(ncid,fldName,'long_name',longName); end;
if ~isempty(units); ncputAtt(ncid,fldName,'units',units); end;
if ~isempty(coord); ncputAtt(ncid,fldName,'coordinates',coord); end; 
if strcmp(fldName,'lon'); ncputAtt(ncid,fldName,'standard_name','longitude'); end;
if strcmp(fldName,'lat'); ncputAtt(ncid,fldName,'standard_name','latitude'); end;
if strcmp(fldName,'dep'); ncputAtt(ncid,fldName,'standard_name','depth'); end;
if strcmp(fldName,'tim'); ncputAtt(ncid,fldName,'standard_name','time'); end;
if strcmp(fldName,'land'); ncputAtt(ncid,fldName,'standard_name','land_binary_mask'); end;
if strcmp(fldName,'area'); ncputAtt(ncid,fldName,'standard_name','cell_area'); end;
if strcmp(fldName,'thic'); ncputAtt(ncid,fldName,'standard_name','cell_thickness'); end;
netcdf.endDef(ncid);
%
if ~fldInIsEmpty; ncputvar(ncid,fldName,fldTile); end;
%
ncclose(ncid);

end;%for ff=1:ntile;

