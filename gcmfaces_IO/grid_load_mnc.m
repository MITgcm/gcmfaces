function []=grid_load_mnc(dirGrid,nFaces,fileFormat,memoryLimit,omitNativeGrid);
%Usage: grid_load_mnc(dirGrid,1,'straight',0,1);

if isempty(whos('memoryLimit')); memoryLimit=0; end;
if isempty(whos('omitNativeGrid')); omitNativeGrid=0; end;

gcmfaces_global; mygrid=[];

mygrid.dirGrid=dirGrid;
mygrid.nFaces=nFaces;
mygrid.fileFormat=fileFormat;

mygrid.gcm2facesFast=false;
mygrid.memoryLimit=memoryLimit;

if nFaces>1; error('Only nFaces=1 has been tested with mnc'); end;
if ~strcmp(fileFormat,'straight'); error('Only fileFormat=''straight'' has been tested with mnc'); end;
if omitNativeGrid==0; omitNativeGrid=1; warning('Only omitNativeGrid=1 has been tested with mnc -- resetting it to 1...'); end;
if memoryLimit>0; memoryLimit=0; warning('Only memoryLimit=0 has been tested with mnc -- resetting it to 0...'); end;

ncload([dirGrid 'grid.glob.nc']);

v0=permute(XC,[2 1]);
mygrid.ioSize=size(v0);
mygrid.facesSize=mygrid.ioSize;
mygrid.facesExpand=[];

list0={'XC','XG','YC','YG','RAC','RAZ','DXC','DXG','DYC','DYG','hFacC','hFacS','hFacW','Depth'};
list1={'XC','XG','YC','YG','rA' ,'rAz','dxC','dxG','dyC','dyG','HFacC','HFacS','HFacW','Depth'};
for iFld=1:length(list0);
      eval(['tmp1=' list1{iFld} ';']);
      nd=length(size(tmp1));
      tmp1=permute(tmp1,[nd:-1:1]);
      tmp2=convert2gcmfaces(tmp1);
      eval(['mygrid.' list0{iFld} '=tmp2;']);
end;

list0={'RC','RF','DRC','DRF'};
list1={'RC','RF','drC','drF'};
for iFld=1:length(list0);
      eval(['tmp1=' list1{iFld} ';']); 
      tmp2=tmp1';
      eval(['mygrid.' list0{iFld} '=tmp2;']);
end;

list0={'DXF','DYF','DXV','DYU','RAW','RAS'};
list1={'dxF','dyF','dxV','dyU','rAw','rAs'};
for iFld=1:length(list0);
      eval(['tmp1=' list1{iFld} ';']);
      nd=length(size(tmp1));
      tmp1=permute(tmp1,[nd:-1:1]);
      tmp2=convert2gcmfaces(tmp1);
      eval(['mygrid.' list0{iFld} '=tmp2;']);
end;

%
warning('Grid is assumed periodic along first dimension only');
mygrid.domainPeriodicity=[1 0];
mygrid.RAZfull=exch_Z(mygrid.RAZ);
%
warning('Grid is assumed to follow lon-lat orientation');
mygrid.AngleCS=mygrid.XC; mygrid.AngleCS(:)=1;
mygrid.AngleSN=mygrid.XC; mygrid.AngleSN(:)=0;
%
mygrid.hFacCsurf=mygrid.hFacC(:,:,1);
mskC=mygrid.hFacC; mskC(mskC==0)=NaN; mskC(mskC>0)=1; mygrid.mskC=mskC;
mskW=mygrid.hFacW; mskW(mskW==0)=NaN; mskW(mskW>0)=1; mygrid.mskW=mskW;
mskS=mygrid.hFacS; mskS(mskS==0)=NaN; mskS(mskS>0)=1; mygrid.mskS=mskS;

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

