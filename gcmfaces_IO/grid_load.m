function []=grid_load(dirGrid,nFaces,fileFormat,memoryLimit,omitNativeGrid);
%object:    load grid information, convert it to gcmfaces format
%           and encapsulate it in the global mygrid structure.
%inputs:    dirGrid is the directory where the grid files (gcm output) can be found.
%           nFaces is the number of faces in this gcm set-up of current interest.
%           fileFormat is the file format ('straight','cube','compact')
%optional:  memoryLimit is a flag that allows the user to omit secondary
%               grid fields in case memory/storage become an issue. It
%               takes 3 values : (0; the default) includes everything
%               (1) omits all 3D fields but hFacC (2) only loads XC & YC.
%           omitNativeGrid is a flag (0 by default) to bypass (when flag 1)
%               grid_load_native and grid_load_native_RAZ calls (that can
%               complement mygrid based upon e.g. tile*.mitgrid files)

if isempty(whos('memoryLimit')); memoryLimit=0; end;
if isempty(whos('omitNativeGrid')); omitNativeGrid=0; end;

gcmfaces_global; mygrid=[];

if nargin==0;%assume that LLC90 grid is used
  if ~isempty(dir('nctiles_grid')); 
    mygrid.dirGrid=['nctiles_grid' filesep];
    mygrid.fileFormat='nctiles';
  elseif ~isempty(dir('GRID'));
    mygrid.dirGrid=['GRID' filesep];
    mygrid.fileFormat='compact';
  elseif ~isempty(dir(['./XC.meta']));
    mygrid.dirGrid=['.' filesep];
    mygrid.fileFormat='compact';
  else;
     fprintf('\n please indicate the grid directory (e.g., ''./'' or ''nctiles_grid/'') \n\n');
     fprintf('   The ECCO v4 grid can be obtained as follows: \n');
     fprintf(['   wget --recursive ftp://mit.ecco-group.org/ecco_for_las/' ...
              'version_4/release1/nctiles_grid \n']);
     fprintf('   mv mit.ecco-group.org/ecco_for_las/version_4/release1/nctiles_grid . \n\n');
     dirGrid=input('');
     mygrid.dirGrid=[dirGrid filesep];
     if ~isempty(dir([mygrid.dirGrid 'GRID.0001.nc']));
       mygrid.fileFormat='nctiles';
     elseif ~isempty(dir([mygrid.dirGrid 'XC.meta']));
       mygrid.fileFormat='compact';
     else;
       error(['could not find grid files in ' mygrid.dirGrid]);
     end;
  end;
  mygrid.nFaces=5;
  mygrid.gcm2facesFast=false;
  mygrid.memoryLimit=0;
  omitNativeGrid=isempty(dir([mygrid.dirGrid 'tile001.mitgrid']));
else;%user specified settings
  mygrid.dirGrid=dirGrid;
  mygrid.nFaces=nFaces;
  mygrid.fileFormat=fileFormat;
  mygrid.gcm2facesFast=false;
  mygrid.memoryLimit=memoryLimit;
end;

if mygrid.memoryLimit>0;
    gcmfaces_msg(['* Warning from grid_load : memoryLimit>0 ' ...
        'may precludes advanced gmcfaces functions.'],'');
end;
if mygrid.memoryLimit>1;
    gcmfaces_msg(['* Warning from grid_load : memoryLimit>1 ' ...
        'may only allow for basic fields displays.'],'');
end;

if strcmp(mygrid.fileFormat,'nctiles');
    mygrid.ioSize=[90 1170];
    mygrid.facesSize=[[90 270];[90 270];[90 90];[270 90];[270 90];[90 90]];
    mygrid.facesExpand=[];
elseif ~isempty(dir([mygrid.dirGrid 'grid.specs.mat']));
    specs=open([mygrid.dirGrid 'grid.specs.mat']);
    mygrid.ioSize=specs.ioSize;
    mygrid.facesSize=specs.facesSize;
    mygrid.facesExpand=specs.facesExpand;
    %example for creating grid.specs.mat, to put in dirGrid :
    %ioSize=[364500 1];
    %facesSize=[[270 450];[0 0];[270 270];[180 270];[450 270]];
    %facesExpand=[270 450];
    %save grid.specs.mat ioSize facesSize facesExpand;
elseif strcmp(mygrid.fileFormat,'compact');
    v0=rdmds([mygrid.dirGrid 'XC']);
    mygrid.ioSize=size(v0);
    nn=size(v0,1); pp=size(v0,2)/nn;
    mm=(pp+4-mygrid.nFaces)/4*nn;
    mygrid.facesSize=[[nn mm];[nn mm];[nn nn];[mm nn];[mm nn];[nn nn]];
    mygrid.facesExpand=[];
elseif strcmp(mygrid.fileFormat,'cube');
    v0=rdmds([mygrid.dirGrid 'XC']);
    mygrid.ioSize=size(v0);
    nn=size(v0,2);
    mygrid.facesSize=[[nn nn];[nn nn];[nn nn];[nn nn];[nn nn];[nn nn]];
    mygrid.facesExpand=[];
elseif strcmp(mygrid.fileFormat,'straight');
    v0=rdmds([mygrid.dirGrid 'XC']);
    mygrid.ioSize=size(v0);
    mygrid.facesSize=mygrid.ioSize;
    mygrid.facesExpand=[];
end;

mygrid.missVal=NaN;%will be set to 0 once the grid has been loaded.

if  ~(mygrid.nFaces==1&strcmp(mygrid.fileFormat,'straight'))&...
        ~(mygrid.nFaces==6&strcmp(mygrid.fileFormat,'cube'))&...
        ~(mygrid.nFaces==6&strcmp(mygrid.fileFormat,'compact'))&...
        ~(mygrid.nFaces==5&strcmp(mygrid.fileFormat,'compact'))&...
        ~(mygrid.nFaces==5&strcmp(mygrid.fileFormat,'nctiles'));
    error('non-supported grid topology');
end;

if strcmp(mygrid.fileFormat,'nctiles');
  %place holders (needed for read_nctiles)
  tmp1=NaN*zeros(90,270);
  tmp2=NaN*zeros(90,90);
  tmp3=NaN*zeros(270,90);
  mygrid.XC=gcmfaces({tmp1,tmp1,tmp2,tmp3,tmp3});
  mygrid.YC=gcmfaces({tmp1,tmp1,tmp2,tmp3,tmp3});
  mygrid.RC=NaN*zeros(50,1);
  clear tmp?;
end;

%the various grid fields:
if mygrid.memoryLimit==0;
    list0={'XC','XG','YC','YG','RAC','RAZ','DXC','DXG','DYC','DYG','hFacC','hFacS','hFacW','Depth'};
elseif mygrid.memoryLimit==1;
    list0={'XC','XG','YC','YG','RAC','RAZ','DXC','DXG','DYC','DYG','hFacC','Depth'};
elseif mygrid.memoryLimit==2;
    list0={'XC','YC'};
end;

for iFld=1:length(list0);
    if ~strcmp(mygrid.fileFormat,'nctiles');
      eval(['mygrid.' list0{iFld} '=rdmds2gcmfaces([mygrid.dirGrid ''' list0{iFld} '*'']);']);
    else;
      eval(['mygrid.' list0{iFld} '=read_nctiles([mygrid.dirGrid ''GRID''],''' list0{iFld} ''');']);
    end;
end;

%the vertical grid
list0={'RC','RF','DRC','DRF'};
for iFld=1:length(list0);
    if ~strcmp(mygrid.fileFormat,'nctiles');
      eval(['mygrid.' list0{iFld} '=squeeze(rdmds([mygrid.dirGrid ''' list0{iFld} '*'']));']);
    else;
      eval(['ncload ' mygrid.dirGrid 'GRID.0001.nc ' list0{iFld} ';']);
      eval(['mygrid.' list0{iFld} '=' list0{iFld} ''';']);
      if strcmp(list0{iFld},'RF'); mygrid.RF=[mygrid.RF;NaN]; end;
    end;
end;

%grid orientation
if mygrid.memoryLimit<2;
    list0={'AngleCS','AngleSN'};
    test0=~isempty(dir([mygrid.dirGrid 'AngleCS*']));
    if strcmp(mygrid.fileFormat,'nctiles');
        for iFld=1:length(list0);
            eval(['mygrid.' list0{iFld} '=read_nctiles([mygrid.dirGrid ''GRID''],''' list0{iFld} ''');']);
        end;
    elseif test0;
        for iFld=1:length(list0);
            eval(['mygrid.' list0{iFld} '=rdmds2gcmfaces([mygrid.dirGrid ''' list0{iFld} '*'']);']);
        end;
    else;
        warning('\n AngleCS/AngleSN not found; set to 1/0 assuming lat/lon grid.\n');
        mygrid.AngleCS=mygrid.XC; mygrid.AngleCS(:)=1;
        mygrid.AngleSN=mygrid.XC; mygrid.AngleSN(:)=0;
    end;
end;

%if the native grid is found then re-load (to benefit from double precision & avoid blank tile issues)
files=dir([mygrid.dirGrid 'grid_cs32*bin']);
if isempty(files); files=dir([mygrid.dirGrid 'tile*.mitgrid']); end;
%logic above needs fixing since I think blank tiles show 0 rather than NaN on some machines
if (length(files)==mygrid.nFaces)&~omitNativeGrid;
  grid_load_native;
  %replace NaNs with 0s if needed (blank tile only issue)
  list0={'hFacC','hFacS','hFacW','Depth','AngleCS','AngleSN'};
  for ii=1:length(list0); 
    eval(['tmp1=mygrid.' list0{ii} ';']);
    tmp1(isnan(tmp1))=0;
    eval(['mygrid.' list0{ii} '=tmp1;']);
  end;
  %reset angles if needed (blank tile only issue)
  tmp1=mygrid.AngleCS.^2+mygrid.AngleSN.^2;
  tmp1=1*(tmp1>0.999&tmp1<1.001);
  mygrid.AngleCS(tmp1==0)=1;
  mygrid.AngleSN(tmp1==0)=0;
end;

%get full RAZ (incl. 'extra line and column') needed for e.g. rotational computations
if mygrid.memoryLimit<2&~omitNativeGrid;
    grid_load_native_RAZ;
end;

%grid masks
if mygrid.memoryLimit<1;
    mygrid.hFacCsurf=mygrid.hFacC;
    for ff=1:mygrid.hFacC.nFaces; mygrid.hFacCsurf{ff}=mygrid.hFacC{ff}(:,:,1); end;
    
    mskC=mygrid.hFacC; mskC(mskC==0)=NaN; mskC(mskC>0)=1; mygrid.mskC=mskC;
    mskW=mygrid.hFacW; mskW(mskW==0)=NaN; mskW(mskW>0)=1; mygrid.mskW=mskW;
    mskS=mygrid.hFacS; mskS(mskS==0)=NaN; mskS(mskS>0)=1; mygrid.mskS=mskS;
end;

%zonal mean and sections needed for transport computations
% if mygrid.memoryLimit<1;
%     if ~isfield(mygrid,'mygrid.LATS_MASKS');
%         gcmfaces_lines_zonal;
%         mygrid.LATS=[mygrid.LATS_MASKS.lat]';
%     end;
%     if ~isfield(mygrid,'LINES_MASKS');
%         [lonPairs,latPairs,names]=gcmfaces_lines_pairs;
%         gcmfaces_lines_transp(lonPairs,latPairs,names);
%     end;
% end;

%to allow convert2gcmfaces/doFast:
if isempty(mygrid.facesExpand)&mygrid.memoryLimit<2;
    tmp1=convert2gcmfaces(mygrid.XC);
    tmp1(:)=[1:length(tmp1(:))];
    nn=length(tmp1(:));
    mygrid.gcm2faces=convert2gcmfaces(tmp1);
    mygrid.faces2gcmSize=size(tmp1);
    mygrid.faces2gcm=convert2gcmfaces(tmp1);
    for iFace=1:mygrid.nFaces;
        n=length(mygrid.gcm2faces{iFace}(:));
        mygrid.faces2gcm{iFace}=mygrid.gcm2faces{iFace}(:);
        mygrid.gcm2faces{iFace}=sparse([1:n],mygrid.gcm2faces{iFace}(:),ones(1,n),n,nn);
    end;
    mygrid.gcm2facesFast=true;
end;

%reset missVal parameter to 0. 
%Note : this is only used by convert2widefaces, for runs with cropped grids.
%Note : 0 should not be used as a fill for the grid itself (NaN was used).
mygrid.missVal=0;

mygrid.dirGrid=[pwd filesep mygrid.dirGrid];
    
