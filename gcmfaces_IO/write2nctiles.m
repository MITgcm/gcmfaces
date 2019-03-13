function [dimOut]=write2nctiles(fileOut,fldIn,doCreate,varargin);
% WRITE2NCTILES writes a gcmfaces object to nctiles, tiled netcdf, files
%
% inputs :
%    - fileOut is the name of the file to be created
%    - fldIn is the array to write to disk
%    - doCreate: if 1 (default) then create file ; if 0 then append to file.
%
% additional paramaters can be provided afterwards in the {'name',value} form:
%         'fldName' is the nc variable name for fld (see "notes" regarding default)
%         'longName' is the corresponding long name ('' by default).
%         'units' is the unit of fld ('(unknown)' by default).
%         'missval' is the missing value (NaN by default).
%         'fillval' is the fill value (NaN by default).
%         'tileNo' is a map of tile indices (face # by default)
%         'coord' is auxilliary coordinates attribute (e.g. 'lon lat dep')
%         'dimIn' is a structure that contains dimlist, dimname, dimsize, etc (see below); it
%            is normally returned as output on the first pass and is passed as input arg afterwards.
%         'dimlist' is the list of dimension names
%         'dimname' is the list of long names associated with dimlist
%         'dimsize' is the list of array sizes associated with dimlist
%         'clmbnds' provides time intervals (nt x 2 cell array; if climatology).
%         'xtype' is the variable ('double' by default)
%         'rdm' is the extended estimate description ('' by default).
%         'descr' is the file description ('' by default).
%
% notes:
%    - if fldName is not explicitly specified then the input variable
%      name (if ok) or file name (otherwise) is used as fldName.
%    - if dimlist is not provided then it is set to 'i1,i2,...'
%    - if dimname is not provided then it is set ot 'array index 1','array index 2', etc
%    - if non-empty clmbnds is provided then a 'climatology' attribute is added to the
%      time coordinate variable which wil point towards the 'climatology_bounds' variable
%
% examples:
%
%    write2nctiles('test1',mygrid.RAC,1,{'fldName','RAC'});
%    RAC=read_nctiles('test1','RAC');
%
%    write2nctiles('test2',mygrid.RAC);
%    RAC=read_nctiles('test2','test2');
%    RAC=read_nctiles('test2');

gcmfaces_global;
if ~(myenv.useNativeMatlabNetcdf);
    error('only native matlab nectdf is supported in write2nctiles');
end;

doCheck=0;%set to one to print stuff to screen

if isempty(whos('fileOut')); error('fileOut must be specified'); end;
if isempty(whos('fldIn')); error('fldIn must be specified'); end;
if isempty(whos('doCreate')); doCreate=1; end;

fldInIsaGcmfaces=isa(fldIn,'gcmfaces');
if fldInIsaGcmfaces;
    fldInIsEmpty=isempty(fldIn{1});
else;
    fldInIsEmpty=isempty(fldIn);
end;

%set more optional paramaters to default values
fldName=inputname(2);
if isempty(fldName);
    [tmp1,fldName,tmp2] = fileparts(fileOut);
end;
longName=''; units='(unknown)'; missval=NaN; fillval=NaN;
coord=''; dimIn=[]; dimlist=[]; dimname=[]; dimsize=[];
if isa(mygrid.XC,'gcmfaces')
    tileNo=mygrid.XC;
else
    tileNo = gcmfaces({zeros(size(mygrid.XC,1),size(mygrid.YC,2))});
end
for ff=1:mygrid.nFaces; tileNo{ff}(:)=ff; end;
clmbnds=[]; xtype='double'; descr=''; rdm=''; TIME_UNLIMITED = 0;

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
                strcmp(varargin{ii}{1},'dimIn')|...
                strcmp(varargin{ii}{1},'dimlist')|...
                strcmp(varargin{ii}{1},'dimname')|...
                strcmp(varargin{ii}{1},'dimsize')|...
                strcmp(varargin{ii}{1},'clmbnds')|...
                strcmp(varargin{ii}{1},'xtype')|...
                strcmp(varargin{ii}{1},'TIME_UNLIMITED')|...
                strcmp(varargin{ii}{1},'start');
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
    
    if TIME_UNLIMITED % Only one time step, need to add time dimension
        fldTile = reshape(fldTile,1,size(fldTile,1),size(fldTile,2),size(fldTile,3));
    end
    
    %select dimensions of relevance:
    if ~fldInIsEmpty;
        nDim=length(size(fldTile));
        dimsize=size(fldTile);
    elseif ~isempty(dimsize);
        nDim=length(dimsize);
    else;
        error('undertermined array size');
    end;
    
    %complement dimension specs as needed:
    need_dimlist=isempty(dimlist)&&doCreate;
    need_dimname=isempty(dimname)&&doCreate;
    need_dimvec=doCreate;
    for iDim=1:nDim;
        if dimsize(iDim)~=1;
            if need_dimlist; dimlist{iDim}=['i' num2str(iDim)]; end;
            if need_dimname; dimname{iDim}=['array index ' num2str(iDim)]; end;
            if need_dimvec; eval(['dimvec.' dimlist{iDim} '=[1:dimsize(iDim)];']); end;
        end;
    end;
    
    %omit singleton dimensions:
    if TIME_UNLIMITED % if time is unlimited allow singleton time dimension
        ii=find(dimsize~=1 + strcmp(dimlist,'tim'));
    else
        ii=find(dimsize~=1);
    end
    dimsize=dimsize(ii);
    if need_dimlist || length(dimlist) > length(dimsize); dimlist={dimlist{ii}}; end; %LM: handle single time step
    if need_dimlist || length(dimname) > length(dimsize); dimname={dimname{ii}}; end;
    
    %check :
    if doCheck&doCreate&ff==1;
        whos fldTile
        descr
        fldName
        longName
        units
        missval
        fillval
        dimlist
        dimname
        dimsize
        dimvec
        keyboard;
    end;

    if doCreate;
        %create netcdf file:
        %-------------------
        if prod(dimsize)*4/1e9<1.5 && ~TIME_UNLIMITED;%use (always available) basic netcdf:
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
        if length(rdm)>0; pp=length(rdm)+1; tmp1=char(pp+63); else; tmp1='A'; end;
        netcdf.putAtt(ncid,nc_global,tmp1,'file created using gcmfaces_IO/write2nctiles.m');
        ncputAtt(ncid,'','date',date);
        netcdf.putAtt(ncid,nc_global,'Conventions','CF-1.6')
        
        ncputAtt(ncid,'','_FillValue',fillval);
        ncputAtt(ncid,'','missing_value',missval);
        
        ncputAtt(ncid,'','itile',ff);
        ncputAtt(ncid,'','ntile',ntile);
        
        %ncdefDim(ncid,'itxt',30);
        
        for dd=1:length(dimlist)
            if strcmp(dimlist{dd},'tim') && TIME_UNLIMITED
                ncdefDim(ncid,dimlist{dd},netcdf.getConstant('UNLIMITED'))
            else
                ncdefDim(ncid,dimlist{dd},dimsize(dd))
            end
        end
        if ~isempty(clmbnds); ncdefDim(ncid,'tcb',2); end;
        
        for dd=1:length(dimlist);
            ncdefVar(ncid,dimlist{dd},'double',{dimlist{dd}});
            ncputAtt(ncid,dimlist{dd},'long_name',dimname{dd});
            ncputAtt(ncid,dimlist{dd},'units','1');
        end;
        ncclose(ncid);
        
        %fill in the dimensions dimensions values vectors:
        %-------------------------------------------------
        ncid=ncopen(fileTile,'write');
        for dd=1:length(dimlist);
            if ~(strcmp(dimlist{dd},'tim') && TIME_UNLIMITED) % don't write time var for unlimited time
                ncputvar(ncid,dimlist{dd},getfield(dimvec,dimlist{dd}));
            end
        end;
        ncclose(ncid);
    end;
    
    %use dimension specified by user
    if ~isempty(dimIn); dimlist=dimIn{ff}; end;
    
    %output dimension information
    dimOut{ff}=dimlist;

    %define and fill field:
    %----------------------
    ncid=ncopen(fileTile,'write');
    finfo = ncinfo(fileTile);
    %
    netcdf.reDef(ncid);
    if ~any(strcmp({finfo.Variables(:).Name},fldName)) % Create variable if it hasn't been created yet
        %ncdefVar(ncid,fldName,xtype,flipdim(dimlist(2:end),2));
        ncdefVar(ncid,fldName,xtype,flipdim(dimlist,2));%note the direction flip
    end
    if ~isempty(longName); ncputAtt(ncid,fldName,'long_name',longName); end;
    if ~isempty(units); ncputAtt(ncid,fldName,'units',units); end;
    if ~isempty(coord); ncputAtt(ncid,fldName,'coordinates',coord); end;
    if strcmp(fldName,'lon'); ncputAtt(ncid,fldName,'standard_name','longitude'); end;
    if strcmp(fldName,'lat'); ncputAtt(ncid,fldName,'standard_name','latitude'); end;
    if strcmp(fldName,'dep_c')||strcmp(fldName,'dep_l')||strcmp(fldName,'dep_u');
              ncputAtt(ncid,fldName,'standard_name','depth');
              ncputAtt(ncid,fldName,'positive','down');
    end;
    if strcmp(fldName,'tim');
        ncputAtt(ncid,fldName,'standard_name','time');
        if ~isempty(clmbnds);
            ncputAtt(ncid,fldName,'climatology','climatology_bounds');
            ncdefVar(ncid,'climatology_bounds',xtype,{'tcb' dimlist{1}});%note the direction flip
            ncputAtt(ncid,'climatology_bounds','long_name','climatology_bounds');
            ncputAtt(ncid,'climatology_bounds','units',units);
        end;
    end;
    if strcmp(fldName,'land'); ncputAtt(ncid,fldName,'standard_name','land_binary_mask'); end;
    if strcmp(fldName,'area'); ncputAtt(ncid,fldName,'standard_name','cell_area'); end;
    if strcmp(fldName,'thic'); ncputAtt(ncid,fldName,'standard_name','cell_thickness'); end;
    netcdf.endDef(ncid);
    %
    
    if ~fldInIsEmpty
        if TIME_UNLIMITED
            count = [1 dimsize(2:end)];
            ncputvar(ncid,fldName,fldTile,start,count);
        else
            ncputvar(ncid,fldName,fldTile);
        end
    end
    %
    if ~isempty(clmbnds);
        ncputvar(ncid,'climatology_bounds',clmbnds);
    end;
    %
    ncclose(ncid);
    
end;%for ff=1:ntile;

