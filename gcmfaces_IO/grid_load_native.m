function []=grid_load_native(dirGrid,nFaces,doWarn);
%object:    load NATIVE FORMAT grid information, convert it to gcmfaces format
%           and encapsulate it in the global mygrid structure.
%inputs:    dirGrid is the directory where the grid files (gcm output) can be found.
%           nFaces is the number of faces in this gcm set-up of current interest.
%
%note:      - originally from /net/ross/raid2/gforget/mygrids/gael_code_v2/faces2mitgcm/mitgcmmygrid_read.m
%           - the hardcoded useChrisFormat allows to recover Chris' format used by the grid generation routines
%
%examples of dirGrid:
%dirGrid='/net/weddell/raid3/gforget/mygrids/mygridCompleted/cube_FM/cube_96/';
%dirGrid='/net/weddell/raid3/gforget/mygrids/mygridCompleted/llcRegLatLon/llc_96/';
%dirGrid='/net/weddell/raid3/gforget/mygrids/mygridCompleted/llpcRegLatLon/llpc_96/';
%dirGrid='/net/weddell/raid3/gforget/mygrids/mygridCompleted/llcMoreTrop/eccollc_96/';
%dirGrid='/net/weddell/raid3/gforget/mygrids/mygridCompleted/llcRegLatLon/llc_540/';
%dirGrid='/net/weddell/raid3/gforget/mygrids/mygridCompleted/cube_FM/cube_32/';
%dirGrid='/net/weddell/raid3/gforget/mygrids/mygridCompleted/cs32_tutorial_held_suarez_cs/';

useChrisFormat=1;
if useChrisFormat==1;
    global MM Nfaces;
    global dyG dxG dxF dyF dxC dyC dyU dxV rA rAw rAs rAz xC yC xG yG xS yS xW yW;
end;

if isempty(whos('doWarn')); doWarn=1; end;

global mygrid;
mygrid.dirGrid=dirGrid;
mygrid.nFaces=nFaces;
mygrid.fileFormat='native';

%search for native grid files
files=dir([dirGrid '*bin']);
while length(files)~=nFaces;
  fprintf('dirGrid does not contain the expected number of ''*.bin'' grid files\n');
  nm=input('please specify file name pattern for the native grid such as ''llc*.bin''\n');
  files=dir([dirGrid nm]);
end;

%discard intermediate step grid files:
tmp1=[];
for ii=1:length(files); 
    if isempty(strfind(files(ii).name,'FM')); tmp1=[tmp1;ii]; end; 
end;
files=files(tmp1);

%list fields of interest and their sizes
list_fields2={'XC','YC','DXF','DYF','RAC','XG','YG','DXV','DYU','RAZ',...
    'DXC','DYC','RAW','RAS','DXG','DYG'};
list_fields={'xC','yC','dxF','dyF','rA','xG','yG','dxV','dyU','rAz',...
    'dxC','dyC','rAw','rAs','dxG','dyG'};
list_x={'xC','xC','xC','xC','xC','xG','xG','xG','xG','xG',...
    'xW','xS','xW','xS','xS','xW'};
list_y={'yC','yC','yC','yC','yC','yG','yG','yG','yG','yG',...
    'yW','yS','yW','yS','yS','yW'};
list_ni={'ni','ni','ni','ni','ni','ni+1','ni+1','ni+1','ni+1','ni+1',...
    'ni+1','ni','ni+1','ni','ni','ni+1'};
list_nj={'nj','nj','nj','nj','nj','nj+1','nj+1','nj+1','nj+1','nj+1',...
    'nj','nj+1','nj','nj+1','nj+1','nj'};

if nFaces~=length(files); 
    error('wrong specification of nFaces');
else;
    Nfaces=length(files);
end;

for iFile=1:Nfaces;
    tmp1=files(iFile).name;
    %we need to know the face dimensions
    if ~isempty(strfind(dirGrid,'cs32_tutorial_held_suarez_cs'))|...
            ~isempty(strfind(dirGrid,'GRIDcube'));%cs32
        ni=32; nj=32;
    else;%get the face dimensions form the file name
        tmp2=strfind(tmp1,'_');
        ni=str2num(tmp1(tmp2(2)+1:tmp2(3)-1));
        nj=str2num(tmp1(tmp2(3)+1:end-4));
    end;
    if iFile==1; MM=ni; end;
    fid=fopen([dirGrid files(iFile).name],'r','b');
    for iFld=1:length(list_fields);
        eval(['nni=' list_ni{iFld} ';']);
        eval(['nnj=' list_nj{iFld} ';']);
        tmp1=fread(fid,[ni+1 nj+1],'float64');
        if useChrisFormat;
           eval([list_fields{iFld} '{' num2str(iFile) '}.vals=tmp1(1:nni,1:nnj);']);
           eval([list_fields{iFld} '{' num2str(iFile) '}.x=''' list_x{iFld} ''';']);
        end;
        if iFile==1; eval(['mygrid.' list_fields2{iFld} '=gcmfaces;']); end;
        eval(['mygrid.' list_fields2{iFld} '{iFile}=tmp1(1:ni,1:nj);']);
    end;
    fclose(fid);
    if useChrisFormat;
       xS{iFile}.vals=(xG{iFile}.vals(2:end,:)+xG{iFile}.vals(1:end-1,:))/2;
       yS{iFile}.vals=(yG{iFile}.vals(2:end,:)+yG{iFile}.vals(1:end-1,:))/2;
       xW{iFile}.vals=(xG{iFile}.vals(:,2:end)+xG{iFile}.vals(:,1:end-1))/2;
       yW{iFile}.vals=(yG{iFile}.vals(:,2:end)+yG{iFile}.vals(:,1:end-1))/2;
   end;
end;

if doWarn;
  list0={'hFacC','hFacS','hFacW','Depth','AngleCS','AngleSN'};
  for ff=1:length(list0); warning(['native file miss ' list0{ff}]); end;
  fprintf('\n\n    which will severely limit diagnostic computations.\n');
  fprintf(' So you may want to get a full grid from an MITgcm run.\n');
end;

