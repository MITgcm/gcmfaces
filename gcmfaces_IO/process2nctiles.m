function []=process2nctiles(dirModel,fileModel,fldModel,tileSize);
%process2nctiles(dirModel);
%object : convert MITgcm binary output to netcdf files (tiled) 
%inputs : dirModel is the MITgcm run directory
%           It is expected to contain binaries in 
%           'diags/STATE/', 'diags/TRSP/', etc. as well
%           as the 'available_diagnostics.log' text file.
%         fileModel the file name base e.g. 'state_2d_set1'
%           By default : all variables in e.g. 'state_2d_set1*' 
%           files will be processed, and writen individually to
%           nctiles (tiled netcdf) that will be located in 'nctiles/'
%         fldModel (by default []) can be specified (as e.g. 'ETAN')
%            when fldModel is empty, all fields are processed
%         tileSize (optional) is e.g. [90 90] (by default tiles=faces) 
%output : (netcdf files)

gcmfaces_global;

%listFiles={'state_2d_set1','state_2d_set2','state_3d_set1','state_3d_set2'};
%listFiles={'trsp_3d_set1','trsp_3d_set2','trsp_3d_set3'};
%for ff=1:length(listFiles); process2nctiles('iter12/',listFiles{ff},[],[90 90]); end;

%replace time series with monthly climatology?
doClim=0;

%directory names
listDirs={'STATE/','TRSP/'};%BUDG?
filAvailDiag=[dirModel 'available_diagnostics.log'];
filReadme=[dirModel 'README'];
dirOut=[dirModel 'nctiles_tmp/'];
%dirOut=[dirModel 'nctiles_post_tmp/'];
if ~isdir(dirOut); mkdir(dirOut); end;

%search in subdirectories
subDir=[];
diagsDir='diags/';
%diagsDir='diags_post/'; 
%diagsDir='diags_interp/';
for ff=1:length(listDirs);
tmp1=dir([dirModel diagsDir listDirs{ff} fileModel '*']);
if ~isempty(tmp1); subDir=listDirs{ff}; end;
end;

if isempty(subDir);
tmp1=dir([dirModel diagsDir fileModel '/' fileModel '*']);
if ~isempty(tmp1); subDir=[fileModel '/']; end;
end;

if isempty(subDir); 
  error(['file ' fileModel ' was not found']);
else;
  dirIn=[dirModel diagsDir subDir];
  nn=length(dir([dirIn fileModel '*data']));
  fprintf('%s (%d files) was found in \n %s \n',fileModel,nn,dirIn);
end;

%set list of variables to process
if ~isempty(fldModel);
   if ischar(fldModel); listFlds={fldModel};
   else; listFlds=fldModel;
   end;
else;
   meta=read_meta([dirIn fileModel '*']);
   listFlds=meta.fldList;
end;

%determine map of tile indices (by default tiles=faces)
if isempty(whos('tileSize'));
  tileNo=mygrid.XC; 
  for ff=1:mygrid.nFaces; tileNo{ff}(:)=ff; end;
else;
  tileNo=gcmfaces_loc_tile(tileSize(1),tileSize(2));
end;

%now do the actual processing
for vv=1:length(listFlds);
nameDiag=deblank(listFlds{vv}) 

%get meta information
meta=read_meta([dirIn fileModel '*']);
irec=find(strcmp(deblank(meta.fldList),nameDiag));
if length(irec)~=1; error('field not in file\n'); end;

%read time series
myDiag=rdmds2gcmfaces([dirIn fileModel '*'],NaN,'rec',irec);

%replace time series with monthly climatology
if doClim; myDiag=compClim(myDiag); end;

%set ancilliary time variable
nn=length(size(myDiag{1}));
nn=size(myDiag{1},nn);
%tim=[1:nn];
tim=[1992*ones(nn,1) [1:nn]' 15*ones(nn,1)];
tim=datenum(tim)-datenum([1992 1 0]);
timUnits='days since 1992-1-1 0:0:0';

%get time step axis
[listTimes]=diags_list_times({dirIn},{fileModel});

%get units and long name from available_diagnostics.log
[avail_diag]=read_avail_diag(filAvailDiag,nameDiag);

%get description of estimate from README
[rdm]=read_readme(filReadme);
disp(rdm');

%set output directory/file name
myFile=[dirOut nameDiag];%first instance is for subdirectory name
if ~isdir(myFile); mkdir(myFile); end;
myFile=[myFile filesep nameDiag];%second instance is for file name base

%get grid params
[grid_diag]=set_grid_diag(avail_diag);

%apply mask, and convert to land mask
if ~isempty(mygrid.RAC);
  msk=grid_diag.msk;
  if length(size(myDiag{1}))==3;
    msk=repmat(msk(:,:,1),[1 1 size(myDiag{1},3)]);
  else;
    msk=repmat(msk,[1 1 1 size(myDiag{1},4)]);
  end;
  myDiag=myDiag.*msk;
  clear msk;
  %
  land=isnan(grid_diag.msk);
end;

%set 'coord' attribute
if avail_diag.nr~=1;
  coord='lon lat dep tim';
else;
  coord='lon lat tim';
end;

%replace time series with monthly climatology
if doClim;
  listTimes=listTimes(1:12);
  timUnits='days since year-1-1 0:0:0';
  avail_diag.longNameDiag=[avail_diag.longNameDiag ' (climatology) '];
end;

%create netcdf file using write2nctiles
doCreate=1; 
dimlist=write2nctiles(myFile,myDiag,doCreate,{'tileNo',tileNo},...
    {'fldName',nameDiag},{'longName',avail_diag.longNameDiag},...
    {'units',avail_diag.units},{'descr',nameDiag},{'coord',coord},{'rdm',rdm});

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
if isfield(grid_diag,'dep');
    write2nctiles(myFile,grid_diag.dep,doCreate,{'tileNo',tileNo},...
      {'fldName','dep'},{'units','m'},{'dimIn',dim.dep});
end;
write2nctiles(myFile,tim,doCreate,{'tileNo',tileNo},...
  {'fldName','tim'},{'longName','time'},...
  {'units',timUnits},{'dimIn',dim.tim});
if ~isempty(mygrid.RAC);
  write2nctiles(myFile,listTimes,doCreate,{'tileNo',tileNo},...
    {'fldName','timstep'},{'longName','final time step number'},...
    {'units','1'},{'dimIn',dim.tim});
  write2nctiles(myFile,grid_diag.msk,doCreate,{'tileNo',tileNo},...
    {'fldName','land'},{'units','1'},{'longName','land mask'},{'dimIn',dim.threeD});
  write2nctiles(myFile,grid_diag.RAC,doCreate,{'tileNo',tileNo},...
    {'fldName','area'},{'units','m^2'},{'longName','grid cell area'},{'dimIn',dim.twoD});
  if isfield(grid_diag,'dz');
    write2nctiles(myFile,grid_diag.dz,doCreate,{'tileNo',tileNo},...
      {'fldName','thic'},{'units','m'},{'dimIn',dim.dep});
  end;
end;

clear myDiag;

end;%for vv=1:length(listFlds);

function [meta]=read_meta(fileName);

%read meta file
tmp1=dir([fileName '*.meta']); tmp1=tmp1(1).name;
tmp2=strfind(fileName,filesep);
if ~isempty(tmp2); tmp2=tmp2(end); else; tmp2=0; end;
tmp1=[fileName(1:tmp2) tmp1]; fid=fopen(tmp1);
while 1;
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    if isempty(whos('tmp3')); tmp3=tline; else; tmp3=[tmp3 ' ' tline]; end;
end
fclose(fid);

%add meta variables to workspace
eval(tmp3);

%reformat to meta structure
meta.dataprec=dataprec;
meta.nDims=nDims;
meta.nFlds=nFlds;
meta.nrecords=nrecords;
meta.fldList=fldList;
meta.dimList=dimList;
if ~isempty(who('timeInterval')); meta.timeInterval=timeInterval; end;
if ~isempty(who('timeStepNumber'));  meta.timeStepNumber=timeStepNumber; end;

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
    grid_diag.lon=mygrid.XC;
    grid_diag.lat=mygrid.YC;
    grid_diag.msk=mygrid.mskC(:,:,1:avail_diag.nr);
elseif strcmp(avail_diag.loc_h,'W');
    grid_diag.lon=mygrid.XG;
    grid_diag.lat=mygrid.YC;
    grid_diag.msk=mygrid.mskW(:,:,1:avail_diag.nr);
elseif strcmp(avail_diag.loc_h,'S');
    grid_diag.lon=mygrid.XC;
    grid_diag.lat=mygrid.YG;
    grid_diag.msk=mygrid.mskS(:,:,1:avail_diag.nr);
end;
grid_diag.RAC=mygrid.RAC;

%vertical grid
if avail_diag.nr~=1;
    if strcmp(avail_diag.loc_z,'M');
        grid_diag.dep=-mygrid.RC;
        grid_diag.dz=mygrid.DRF;
    elseif strcmp(avail_diag.loc_z,'L');
        grid_diag.dep=-mygrid.RF(2:end);
        grid_diag.dz=[mygrid.DRC(2:end) ; 228.25];%quick fix
    else;
        error('unknown vertical grid');
    end;
    grid_diag.dep=reshape(grid_diag.dep,[1 1 avail_diag.nr]);
    grid_diag.dz=reshape(grid_diag.dz,[1 1 avail_diag.nr]);
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

