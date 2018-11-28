function []=process2nctiles(dirDiags,fileDiags,selectFld,tileSize,iterateOverFiles);
%process2nctiles(dirDiags,fileDiags);
% object : convert MITgcm binary output to netcdf files (tiled)
% inputs : dirDiags is the directory containing binary model output from
%             MITgcm/pkg/diagnostics; dirDiags and its subdirectories will
%             be scanned to locate files that start with the fileDiags prefix;
%             it should also contain two files called available_diagnostics.log
%             and README (see below for additional information).
%         fileDiags the file name base e.g. 'state_2d_set1'
%           By default : all variables in e.g. 'state_2d_set1*'
%           files will be processed, and written individually to
%           nctiles (tiled netcdf) that will be located in 'nctiles/'
%         selectFld (optional) can be specified as, e.g., 1, or 'ETAN', or {'ETAN'};
%            {'ETAN'};; if selectFld is left un-specified or specified as empty
%            then all fields listed in [fileDiags '*.meta'] will be processed;
%            if selectFld is a vector of positive integers then these will be treated
%            as indices in the fields list; if selectFld is a character string or a
%            cell array of strings then each string will be treated as the field name.
%         tileSize (optional) can be specified (e.g., [90 90]); if otherwise
%            then tile sizes will be set to face sizes (i.e., mygrid.facesSize).
%         iterateOverFiles (optional) when set to 1, willset "time" to 
%           unlimited and iterate over files and process one at a time
% Output : (netcdf files)
%
% Notes: available_diagnostics.log (need for documentation ...)
%        rename_diagnostics.mat (need for documentation ...)
%        README (need for documentation ...)
%
% Example: process2nctiles([pwd '/diags_ALL_MDS/'],'ptr_3d_set1','TRAC01',[90 90]);

gcmfaces_global;

if isempty(whos('selectFld')); selectFld=''; end;
if isempty(whos('tileSize')); tileSize=[]; end;
if isempty(whos('iterateOverFiles')); iterateOverFiles=0; end;
TIME_UNLIMITED = iterateOverFiles;

%replace time series with monthly climatology?
%doClim=1; 
doClim=0; if doClim; fprintf('\n Creating monthly climatology (doClim=1) \n\n'); end;

%needed files
filAvailDiag=[dirDiags 'available_diagnostics.log'];
if isempty(dir(filAvailDiag)); error('Missing available_diagnostics.log in dirDiags'); end;

filReadme=[dirDiags 'README'];
if isempty(dir(filReadme)); error('Missing README in dirDiags'); end;

filRename=[dirDiags 'rename_diagnostics.mat'];
if isempty(dir(filRename)); filRename=''; end;

%output directory
dirOut=[dirDiags 'nctiles_tmp/'];
if ~isdir(dirOut); mkdir(dirOut); end;

%search for fileDiags in subdirectories
[subDir]=rdmds_search_subdirs(dirDiags,fileDiags);

if isempty(subDir);
    error(['file ' fileDiags ' was not found']);
else;
    dirIn=[dirDiags subDir];
    nn=length(dir([dirIn fileDiags '*data']));
    fprintf('%s (%d files) was found in %s \n',fileDiags,nn,dirIn);
end;

%set list of variables to process
if ~isempty(selectFld)&&ischar(selectFld);
    listFlds={selectFld};
elseif ~isempty(selectFld)&&iscell(selectFld);
    listFlds=selectFld;
else;
    meta=rdmds_meta([dirIn fileDiags]);
    listFlds=meta.fldList;
    if isnumeric(selectFld);
        listFlds={listFlds{selectFld}};
    end;
end;

%determine map of tile indices (by default tiles=faces)
if isempty(tileSize);
    tileNo=mygrid.XC;
    for ff=1:mygrid.nFaces; tileNo{ff}(:)=ff; end;
else;
    tileNo=gcmfaces_loc_tile(tileSize(1),tileSize(2));
end;

%now do the actual processing
for vv=1:length(listFlds);
    nameDiag=deblank(listFlds{vv});
    fprintf(['processing ' nameDiag '... \n']);
    
    %get meta information
    meta=rdmds_meta([dirIn fileDiags]);
    irec=find(strcmp(deblank(meta.fldList),nameDiag));
    if length(irec)~=1; error('field not in file\n'); end;
    
    %read time series LM: setting to read in one time step at a time?
    
    if iterateOverFiles
        fnames = dir([dirIn fileDiags '*.data']);
        tim = zeros(length(fnames),1);
        
        nn = length(fnames);
        begtim=[1992*ones(nn,1) [1:nn]' ones(nn,1)];
        begtim=datenum(begtim)-datenum([1992 1 1]);
        endtim=[1992*ones(nn,1) [1:nn]' 1+ones(nn,1)];
        endtim=datenum(endtim)-datenum([1992 1 1]);
        timUnits='days since 1992-1-1 0:0:0';
        clmbnds=[];
    else
        fnames = {[dirIn fileDiags '*']};
    end
    
    %get units and long name from available_diagnostics.log
   [avail_diag]=read_avail_diag(filAvailDiag,nameDiag);
     
    %rename variable if needed
    nameDiagOut=nameDiag;
    if ~isempty(filRename);
        load(filRename); ii=find(strcmp(listNameIn,nameDiag));
        if ~isempty(ii); nameDiagOut=listNameOut{ii}; end;
    end;
    
    %get description of estimate from README
    [rdm]=read_readme(filReadme);
    disp(rdm');
    
    %set output directory/file name
    myFile=[dirOut nameDiagOut];%first instance is for subdirectory name
    if ~isdir(myFile); mkdir(myFile); end;
    myFile=[myFile filesep nameDiagOut];%second instance is for file name base
    
    %get grid params
    [grid_diag]=set_grid_diag(avail_diag);
    
    %set 'coord' attribute
    if avail_diag.nr~=1;
        coord='lon lat dep tim';
        dimlist={'t',grid_diag.dimlist{:}};
        dimname={'Time coordinate','Cartesian coordinate 3','Cartesian coordinate 2','Cartesian coordinate 1'};
    else;
        coord='lon lat tim';
        dimlist={'t',grid_diag.dimlist{:}};
        dimname={'Time coordinate','Cartesian coordinate 2','Cartesian coordinate 1'};
    end;
    
    for ff = 1:length(fnames)
        if iscell(fnames)
            myDiag=rdmds2gcmfaces([dirIn fileDiags '*'],NaN,'rec',irec);
            
            %set ancilliary time variable
            nn=length(size(myDiag{1}));
            nn=size(myDiag{1},nn);
            tim=[1992*ones(nn,1) [1:nn]' 15*ones(nn,1)];
            tim=datenum(tim)-datenum([1992 1 1]);
            begtim=[1992*ones(nn,1) [1:nn]' ones(nn,1)];
            begtim=datenum(begtim)-datenum([1992 1 1]);
            endtim=[1992*ones(nn,1) [1:nn]' 1+ones(nn,1)];
            endtim=datenum(endtim)-datenum([1992 1 1]);
            timUnits='days since 1992-1-1 0:0:0';
            clmbnds=[];
        else
            fname = fnames(ff).name;
            extidx = strfind(fname,'.');
            itrs = str2double(fname(extidx(1)+1:extidx(2)-1));
            myDiag=rdmds2gcmfaces([dirIn fileDiags '*'],itrs,'rec',irec);
            
            tim(ff) = itrs;
            
        end
        
        
        
        %if doClim then replace time series with monthly climatology and assign climatology_bounds variable
        if doClim;
            myDiag=compClim(myDiag);
            %set tim to first year values for case of unsupported 'climatology' attribute (see below)
            tim=tim(1:12);
            %'climatology' attribute + 'climatology_bounds' variable will be added as shown at
            %http://cfconventions.org/cf-conventions/v1.6.0/cf-conventions.html#climatological-statistics
            for tt=1:12;
                tmpb=begtim(tt:12:nn); tmpe=endtim(tt:12:nn) ;
                clmbnds=[clmbnds;[tmpb(1) tmpe(end)]];
            end;
        end;
        
        
        %apply mask(, and convert to land mask)
        if isfield(grid_diag,'msk');
            msk=grid_diag.msk;
            if length(size(myDiag{1}))==3;
                msk=repmat(msk(:,:,1),[1 1 size(myDiag{1},3)]);
            else;
                msk=repmat(msk,[1 1 1 size(myDiag{1},4)]);
            end;
            myDiag=myDiag.*msk;
            clear msk;
            %
            %land=isnan(grid_diag.msk);
        end;
        
        %create netcdf file using write2nctiles
        doCreate=1; myDiag=single(myDiag);
        if iterateOverFiles && ff == 1
            start = [0 0 0 0];
            dimlist=write2nctiles(myFile,myDiag,doCreate,{'tileNo',tileNo},...
                {'fldName',nameDiagOut},{'longName',avail_diag.longNameDiag},{'xtype','float'},...
                {'units',avail_diag.units},{'descr',nameDiagOut},{'coord',coord},{'dimlist',dimlist},...
                {'dimname',dimname},{'clmbnds',clmbnds},{'rdm',rdm},{'TIME_UNLIMITED',TIME_UNLIMITED},{'start',start});
        elseif iterateOverFiles
            %for tt = 2:size(myDiag.f1,4)
            doCreate = 0;
            start(1) = ff-1;
            dimlist=write2nctiles(myFile,myDiag,doCreate,{'tileNo',tileNo},...
                {'fldName',nameDiagOut},{'longName',avail_diag.longNameDiag},{'xtype','float'},...
                {'units',avail_diag.units},{'descr',nameDiagOut},{'coord',coord},{'dimlist',dimlist{1}},...
                {'dimname',dimname},{'clmbnds',clmbnds},{'rdm',rdm},{'TIME_UNLIMITED',TIME_UNLIMITED},{'start',start});
            %end
            
        else
            dimlist=write2nctiles(myFile,myDiag,doCreate,{'tileNo',tileNo},...
                {'fldName',nameDiagOut},{'longName',avail_diag.longNameDiag},{'xtype','float'},...
                {'units',avail_diag.units},{'descr',nameDiagOut},{'coord',coord},{'dimlist',dimlist},...
                {'dimname',dimname},{'clmbnds',clmbnds},{'rdm',rdm});
        end
    end
    %determine relevant dimensions
    for ff=1:length(dimlist);
        dim.tim{ff}={dimlist{ff}{1}};
        dim.twoD{ff}={dimlist{ff}{end-1:end}};
        if avail_diag.nr~=1;
            dim.threeD{ff}={dimlist{ff}{end-2:end}};
            dim.dep{ff}={dimlist{ff}{end-2}};
        else;
            dim.threeD{ff}=dim.twoD{ff};
            dim.dep{ff}=[];
        end;
    end;
    
    %prepare to add fields
    doCreate=0;
    
    
    %now add fields
    write2nctiles(myFile,grid_diag.lon,doCreate,{'tileNo',tileNo},...
        {'fldName','lon'},{'units','degrees_east'},{'dimIn',dim.twoD});
    write2nctiles(myFile,grid_diag.lat,doCreate,{'tileNo',tileNo},...
        {'fldName','lat'},{'units','degrees_north'},{'dimIn',dim.twoD});
    %if ~iterateOverFiles
        write2nctiles(myFile,tim,doCreate,{'tileNo',tileNo},{'fldName','tim'},...
            {'longName','time'},{'units',timUnits},{'dimIn',dim.tim},{'clmbnds',clmbnds});
    %end
    if isfield(grid_diag,'dep');
        write2nctiles(myFile,grid_diag.dep,doCreate,{'tileNo',tileNo},...
            {'fldName','dep'},{'units','m'},{'dimIn',dim.dep});
        if isfield(grid_diag,'dz');
            write2nctiles(myFile,grid_diag.dz,doCreate,{'tileNo',tileNo},...
                {'fldName','thic'},{'units','m'},{'dimIn',dim.dep});
        end;
    end;
    if isfield(grid_diag,'msk');
        write2nctiles(myFile,grid_diag.msk,doCreate,{'tileNo',tileNo},...
            {'fldName','land'},{'units','1'},{'longName','land mask'},{'dimIn',dim.threeD});
    end;
    if isfield(grid_diag,'area');
        write2nctiles(myFile,grid_diag.area,doCreate,{'tileNo',tileNo},...
            {'fldName','area'},{'units','m^2'},{'longName','grid cell area'},{'dimIn',dim.twoD});
    end;
    
    clear myDiag;
    
end;%for vv=1:length(listFlds);

%%

function [rdm]=read_readme(filReadme);

gcmfaces_global;

rdm=[];

fid=fopen(filReadme,'rt');
while ~feof(fid);
    nn=length(rdm);
    rdm{nn+1} = fgetl(fid);
end;
fclose(fid);

%%

function [avail_diag]=read_avail_diag(filAvailDiag,nameDiag);

gcmfaces_global;

avail_diag=[];

fid=fopen(filAvailDiag,'rt');
while ~feof(fid);
    tline = fgetl(fid);
    tmp1=8-length(nameDiag); tmp1=repmat(' ',[1 tmp1]);
    tname = ['|' sprintf('%s',nameDiag) tmp1 '|'];
    if ~isempty(strfind(tline,tname));
        %e.g. tline='   235 |SIatmQnt|  1 |       |SM      U1|W/m^2           |Net atmospheric heat flux, >0 decreases theta';
        %
        tmp1=strfind(tline,'|'); tmp1=tmp1(end-1:end);
        avail_diag.units=strtrim(tline(tmp1(1)+1:tmp1(2)-1));
        avail_diag.longNameDiag=tline(tmp1(2)+1:end);
        %
        tmp1=strfind(tline,'|'); tmp1=tmp1(4:5);
        pars=tline(tmp1(1)+1:tmp1(2)-1);
        %
        if strcmp(pars(2),'M'); avail_diag.loc_h='C';
        elseif strcmp(pars(2),'U'); avail_diag.loc_h='W';
        elseif strcmp(pars(2),'V'); avail_diag.loc_h='S';
        end;
        %
        avail_diag.loc_z=pars(9);
        %
        if strcmp(pars(10),'1'); avail_diag.nr=1;
        else; avail_diag.nr=length(mygrid.RC);
        end;
    end;
end;
fclose(fid);

%%

function [grid_diag]=set_grid_diag(avail_diag);

gcmfaces_global;

%switch for non-tracer point values
if strcmp(avail_diag.loc_h,'C');
    grid_diag.lon=mygrid.XC; grid_diag.lat=mygrid.YC;
    if isfield(mygrid,'mskC'); grid_diag.msk=mygrid.mskC(:,:,1:avail_diag.nr); end;
    if isfield(mygrid,'RAC'); grid_diag.area=mygrid.RAC; end;
    grid_diag.dimlist={'j_c','i_c'};
elseif strcmp(avail_diag.loc_h,'W');
    grid_diag.lon=mygrid.XW; grid_diag.lat=mygrid.YW;
    if isfield(mygrid,'mskW'); grid_diag.msk=mygrid.mskW(:,:,1:avail_diag.nr); end;
    if isfield(mygrid,'RAW'); grid_diag.area=mygrid.RAW; end;
    grid_diag.dimlist={'j_w','i_w'};
elseif strcmp(avail_diag.loc_h,'S');
    grid_diag.lon=mygrid.XS; grid_diag.lat=mygrid.YS;
    if isfield(mygrid,'mskS'); grid_diag.msk=mygrid.mskS(:,:,1:avail_diag.nr); end;
    if isfield(mygrid,'RAS'); grid_diag.area=mygrid.RAS; end;
    grid_diag.dimlist={'j_s','i_s'};
elseif strcmp(avail_diag.loc_h,'Z');
    error('remains to be implemented: loc_h=Z');
else;
    error('unimplemeted loc_h case')
end;

%vertical grid
if avail_diag.nr~=1;
    if strcmp(avail_diag.loc_z,'M');
        grid_diag.dep=-mygrid.RC;
        if isfield(mygrid,'DRF'); grid_diag.dz=mygrid.DRF; end;
        grid_diag.dimlist={'k_c',grid_diag.dimlist{:}};
    elseif strcmp(avail_diag.loc_z,'L');
        grid_diag.dep=-mygrid.RF(2:end);
        if isfield(mygrid,'DRC'); grid_diag.dz=mygrid.DRC(2:end); end;
        grid_diag.dimlist={'k_l',grid_diag.dimlist{:}};
    elseif strcmp(avail_diag.loc_z,'U');
        grid_diag.dep=-mygrid.RF(1:end-1);
        if isfield(mygrid,'DRC'); grid_diag.dz=mygrid.DRC(1:end-1); end;
        grid_diag.dimlist={'k_u',grid_diag.dimlist{:}};
    else;
        error('unimplemented loc_z case');
    end;
    grid_diag.dep=reshape(grid_diag.dep,[1 1 avail_diag.nr]);
    if isfield(grid_diag,'dz'); grid_diag.dz=reshape(grid_diag.dz,[1 1 avail_diag.nr]); end;
end;

%%replace time series with monthly climatology
function [FLD]=compClim(fld);

gcmfaces_global;

ndim=length(size(fld{1}));
nyear=size(fld{1},ndim)/12;

if ndim==3; FLD=NaN*fld(:,:,1:12); end;
if ndim==4; FLD=NaN*fld(:,:,:,1:12); end;

for mm=1:12;
    if ndim==3; FLD(:,:,mm)=mean(fld(:,:,mm:12:12*nyear),ndim); end;
    if ndim==4; FLD(:,:,:,mm)=mean(fld(:,:,:,mm:12:12*nyear),ndim); end;
end;

