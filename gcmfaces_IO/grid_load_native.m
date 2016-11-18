function []=grid_load_native(dirGrid,nFaces,doWarn);
%object:    load NATIVE FORMAT grid information, convert it to gcmfaces format
%           and encapsulate it in the global mygrid structure.
%inputs: EITHER
%           dirGrid is the directory where the grid files (gcm output) can be found.
%           nFaces is the number of faces in this gcm set-up of current interest.
%           doWarn issue warning if grid is not complete (e.g. hFacC is missing)
%        OR
%           [] if mygrid has already read by grid_load.m from XC.data, YC.data, etc.
%           from which grid_load_native can get dirGrid and nFaces


global mygrid;

alsoDoTheOldWay=0;
if alsoDoTheOldWay;
    global MM Nfaces;
    global dyG dxG dxF dyF dxC dyC dyU dxV rA rAw rAs rAz xC yC xG yG xS yS xW yW;
end;

if isempty(whos('doWarn')); doWarn=1; end;

if nargin>0;
  mygrid=[];
  mygrid.dirGrid=dirGrid;
  mygrid.nFaces=nFaces;
  mygrid.fileFormat='native';
end;

%search for native grid files
files=dir([mygrid.dirGrid 'grid_cs32*bin']);
if isempty(files); files=dir([mygrid.dirGrid 'tile*.mitgrid']); end;
if isempty(files); files=dir([dirGrid '*bin']); end;
while length(files)~=mygrid.nFaces;
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

if mygrid.nFaces~=length(files); 
    error('wrong specification of nFaces');
else;
    Nfaces=length(files);
end;

for iFile=1:Nfaces;
    tmp1=files(iFile).name;
    %get face dimensions
    if ~isempty(strfind(mygrid.dirGrid,'cs32_tutorial_held_suarez_cs'))|...
            ~isempty(strfind(mygrid.dirGrid,'GRIDcube'));%special case of cs32
        ni=32; nj=32;
    elseif strcmp(tmp1(end-2:end),'bin');%get face dimension from file name
        tmp2=strfind(tmp1,'_');
        ni=str2num(tmp1(tmp2(2)+1:tmp2(3)-1));
        nj=str2num(tmp1(tmp2(3)+1:end-4));
    elseif isfield(mygrid,'XC');%get face dimention from previous grid load
        [ni,nj]=size(mygrid.XC{iFile});
    else;
        error('could not determine face size');
    end;
    if iFile==1&alsoDoTheOldWay; MM=ni; end;
    fid=fopen([mygrid.dirGrid files(iFile).name],'r','b');
    for iFld=1:length(list_fields);
        eval(['nni=' list_ni{iFld} ';']);
        eval(['nnj=' list_nj{iFld} ';']);
        tmp1=fread(fid,[ni+1 nj+1],'float64');
        if alsoDoTheOldWay;
           eval([list_fields{iFld} '{' num2str(iFile) '}.vals=tmp1(1:nni,1:nnj);']);
           eval([list_fields{iFld} '{' num2str(iFile) '}.x=''' list_x{iFld} ''';']);
        end;
        if ~isfield(mygrid,list_fields2{iFld}); eval(['mygrid.' list_fields2{iFld} '=gcmfaces;']); end;
        eval(['mygrid.' list_fields2{iFld} '{iFile}=tmp1(1:ni,1:nj);']);
    end;
    fclose(fid);
    if alsoDoTheOldWay;
       xS{iFile}.vals=(xG{iFile}.vals(2:end,:)+xG{iFile}.vals(1:end-1,:))/2;
       yS{iFile}.vals=(yG{iFile}.vals(2:end,:)+yG{iFile}.vals(1:end-1,:))/2;
       xW{iFile}.vals=(xG{iFile}.vals(:,2:end)+xG{iFile}.vals(:,1:end-1))/2;
       yW{iFile}.vals=(yG{iFile}.vals(:,2:end)+yG{iFile}.vals(:,1:end-1))/2;
   end;
end;

if doWarn;
  list0={'hFacC','hFacS','hFacW','Depth','AngleCS','AngleSN'};
  nWarn=0;
  for ff=1:length(list0); 
    if ~isfield(mygrid,list0{ff}); 
      warning(['The following variable is missing in mygrid: ' list0{ff}]);
      nWarn=nWarn+1;
    end;
  end;
  if nWarn>0; 
    warning('Missing these variables may restrict diagnostic possibilities.');
    nWarn
  end;
end;

