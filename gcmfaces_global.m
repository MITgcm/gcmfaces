function []=gcmfaces_global(varargin);
%object:    take care of path and global variables (mygrid and myenv),
%           and sends global variables to caller routine workspace
%optional inputs: optional paramaters take the following form
%           {'name',param1,param2,...}. Are currently active:
%               {'resetGrid',resetGrid} states that mygrid will be cleared
%                   and re-loaded interactively (1), or not (0;default).
%               {'listVars',varName1,varName2} is a list of variables
%                   to check is in mygrid (empty by default).
%notes:     - in any call, if this has not yet been done,
%           this routine also adds gcmfaces subdirectories
%           to the matlab path, and it defines myenv.
%           - calls to this routine will eventually replace
%           both gcmfaces_path and 'global mygrid' calls.

%set optional paramaters to default values
resetGrid=0; listVars={};
%set more optional paramaters to user defined values
for ii=1:nargin;
    if ~iscell(varargin{ii});
        warning('inputCheck:gcmfaces_global_1',...
            ['As of june 2011, gcmfaces_global expects \n'...
            '         its optional parameters as cell arrays. \n'...
            '         Argument no. ' num2str(ii+1) ' was ignored \n'...
            '         Type ''help gcmfaces_global'' for details.']);
    elseif ~ischar(varargin{ii}{1});
        warning('inputCheck:gcmfaces_global_2',...
            ['As of june 2011, gcmfaces_global expects \n'...
            '         its optional parameters cell arrays \n'...
            '         to start with character string. \n'...
            '         Argument no. ' num2str(ii+1) ' was ignored \n'...
            '         Type ''help gcmfaces_global'' for details.']);
    else;
        if strcmp(varargin{ii}{1},'listVars');
            eval([varargin{ii}{1} '={varargin{ii}{2:end}};']);
        elseif strcmp(varargin{ii}{1},'resetGrid');
            eval([varargin{ii}{1} '=varargin{ii}{2};']);
        else;
            warning('inputCheck:gcmfaces_global_3',...
                ['unknown option ''' varargin{ii}{1} ''' was ignored']);
        end;
    end;
end;


%get/define global variables:
global myenv mygrid;

%take care of path:
test0=which('convert2gcmfaces.m');
if isempty(test0);
    test0=which('gcmfaces_global.m'); ii=strfind(test0,filesep);
    mydir=test0(1:ii(end));
    %
    eval(['addpath ' mydir ';']);
    eval(['addpath ' mydir '/gcmfaces_IO/;']);
    eval(['addpath ' mydir 'gcmfaces_convert/;']);
    eval(['addpath ' mydir 'gcmfaces_exch/;']);
    eval(['addpath ' mydir 'gcmfaces_maps/;']);
    eval(['addpath ' mydir '/gcmfaces_misc/;']);
    eval(['addpath ' mydir '/gcmfaces_calc/;']);
    eval(['addpath ' mydir '/gcmfaces_smooth/;']);
    eval(['addpath ' mydir 'ecco_v4/;']);
    eval(['addpath ' mydir 'sample_analysis/;']);
    eval(['addpath ' mydir 'sample_processing/;']);
    eval(['addpath ' mydir 'gcmfaces_diags/;']);
    eval(['addpath ' mydir 'gcmfaces_devel/;']);
end;

%environment variables:
if isempty(myenv);
    test0=which('gcmfaces_global.m'); ii=strfind(test0,filesep);
    myenv.gcmfaces_dir=test0(1:ii(end));
    myenv.verbose=0;
    myenv.lessplot=0;
    myenv.lesstest=0;
    myenv.useNativeMatlabNetcdf = ~isempty(which('netcdf.open'));
    myenv.issueWarnings=1;
    %... check m_map and netcdf
end;

%load grid variables:
if resetGrid==1;
    mygrid=[];
    dirGrid=input('grid directory name?\n','s');
    nFaces=input('number of grid faces?\n');
    fileFormat=input('file format?\n[''native'',''straight'',''cube'' or ''compact'']\n','s');
    if strcmp(fileFormat,'native');
        grid_load_native(dirGrid,nFaces);
    else;
        grid_load(dirGrid,nFaces,fileFormat);
    end;
end;

%check available mygrid variables:
for ii=1:length(listVars);
    if ~isfield(mygrid,listVars{ii});
        error(['mygrid does not include ' listVars{ii}]);
    end;
end;

%issue warning if mygrid is empty:
test0=~isfield(mygrid,'XC');
[ST,I]=dbstack; ST={ST(:).name}';
test1=1;
list1={'grid_load','startup','example_display','example_IO',...
    'example_remap','example_griddata','example_interp','example_faces2latlon2faces',...
    'example_bin_average','example_transports','example_budget',...
    'profiles_process_init','gcmfaces_init','diags_pre_process','diags_grid'};
list1={list1{:},'profiles_prep_main','profiles_prep_select','MITprof_demo'};
for jj=1:length(list1);
    test1=test1&isempty(find(strcmp(ST,list1{jj})));
end;
if test0&test1&myenv.issueWarnings;
    warning('mygrid has not yet been loaded to memory');
end;

%send to workspace:
evalin('caller','global mygrid myenv');

