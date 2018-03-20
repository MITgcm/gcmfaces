function []=diags_diff_snapshots(dirSnap,dirMat,fileStart);
%object: compute time derivatives between snapshots that 
%   will be compared with time mean flux terms in budgets
%input:     dirSnap is the directory containing the binary snapshots
%           fileStart is the root of file names (e.g. budg2d_snap_set1)
%result:    create e.g. rate_budg2d_snap_set1 files

gcmfaces_global; global myparms;

fileList=dir([dirSnap fileStart '.*.data']);
for ii=1:length(fileList)-1;

%1) get the time of fld0 & fld1, & the data precision
fileName0=fullfile(dirSnap,fileList(ii).name(1:end-5));
meta0=rdmds_meta(fileName0);
fileName1=fullfile(dirSnap,filesep,fileList(ii+1).name(1:end-5));
meta1=rdmds_meta(fileName1);
%
time1=meta1.timeInterval;
time0=meta0.timeInterval;
dataprec=str2num(meta1.dataprec(end-1:end));

%2) get the binary data:
fld0=rdmds(fileName0);
fld1=rdmds(fileName1);

test3d=(length(size(fld0))==4);
if test3d&&(myparms.useNLFS==2);
%3D diagnostics are multiplied by DRF*hFac*ETAN
%(2D diagnostics are expectedly vertically integrated by MITgcm)
  for jj=0:1;
    %get etan
    etanName=['budg2d_snap_set1' fileList(ii+jj).name(end-15:end-5)];
    etanName=fullfile(dirSnap,filesep,etanName);
    etan=rdmds2gcmfaces(etanName,'rec',1);
    %compute time variable thickness
    tmp1=mk3D(mygrid.DRF,mygrid.hFacC).*mygrid.hFacC;
    tmp2=tmp1./mk3D(mygrid.Depth,tmp1);
    tmp2=tmp2.*mk3D(etan,tmp1);
    drf=convert2gcmfaces(tmp1+tmp2);
    %apply to scale fld
    eval(['fld=fld' num2str(jj) ';']);
    n4=size(fld,4);
    drf=repmat(drf,[1 1 1 n4]);
    fld=fld.*drf;
    eval(['fld' num2str(jj) '=fld;']); 
  end;
elseif test3d;
  %the non rstar case remains to be treated
  error('missing implementation of diags_diff_snapshots\n');
end;

%3) compute the tendency term:
fld2=(fld1-fld0)/(time1-time0);

%4) write to file:
fileMetaOld=[dirSnap fileList(ii+1).name(1:end-5) '.meta'];
fileMetaNew=[dirMat 'BUDG/rate_' fileList(ii+1).name(1:end-5) '.meta'];
copyfile(fileMetaOld , fileMetaNew);
fileDataNew=[dirMat 'BUDG/rate_' fileList(ii+1).name(1:end-5) '.data'];
write2file(fileDataNew,fld2,dataprec);

end;

