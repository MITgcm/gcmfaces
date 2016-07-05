function []=diags_budg_geothermal(dirSnap,dirMat,fileStart);
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
fileStartGeothFlux='geothermalFlux';
if strcmp(fileStart,'budg2d_snap_set2');
k=1; test3d=0;
elseif ~isempty(strfind(fileStart,'budg2d_snap_set3'));
k=str2num(fileStart(18:end)); test3d=0;
fileStartGeothFlux=['geothermalFlux_' fileStart(18:end)];
else;
k=1; test3d=1;
end;

%assemble the 3d geothermal flux field (flux entering a given layer at the underlying interface)
fld2d=read_bin([dirSnap 'geothermalFlux.bin']);
fld3d=0*mygrid.mskC;
fld3d=cat(3,fld3d,NaN*fld3d(:,:,1));
nr=length(mygrid.RC);
for kk=1:nr;
  tmp1=fld3d(:,:,kk);
  tmp2=fld3d(:,:,kk+1);
  tmp3=find(isnan(tmp2)&~isnan(tmp1)); 
  tmp1(tmp3)=fld2d(tmp3);
  tmp1(isnan(tmp1))=0;
  fld3d(:,:,kk)=tmp1;
end;

if test3d;
%output 3D field
fld2=fld3d;%maybe we need to switch by 1 level?
error('has not been tested yet');
%
else;
%integrate over underlying interfaces:
fld2=sum(fld3d(:,:,k:nr),3);
end;

%4) write to file:
fileMetaOld=[dirSnap fileList(ii+1).name(1:end-5) '.meta'];
fileIter=fileList(ii+1).name(length(fileStart)+2:1:end-5);
fileMetaNew=[dirMat 'BUDG/' fileStartGeothFlux '.' fileIter '.meta'];
%
fidMetaOld=fopen(fileMetaOld,'r');
fidMetaNew=fopen(fileMetaNew,'w');
test0=1;
while test0;
tmp1=fgetl(fidMetaOld);
test1=isempty(strfind(tmp1,'fldList'));
test2=isempty(strfind(tmp1,'nrecords'));
test3=isempty(strfind(tmp1,'nFlds'));
if test1&test2&test3;
  fprintf(fidMetaNew,[tmp1 '\n']);
elseif ~test3;
  fprintf(fidMetaNew,' nFlds = [    1 ];\n');
elseif ~test2;
  fprintf(fidMetaNew,' nrecords = [     1 ];\n');
else;
  test0=0;
end;
end;
fprintf(fidMetaNew,' fldList = {\n');
fprintf(fidMetaNew,'''geothFlux''\n');
fprintf(fidMetaNew,' };\n');
fclose(fidMetaOld);
fclose(fidMetaNew);
%
fileDataNew=[dirMat 'BUDG/' fileStartGeothFlux '.' fileIter '.data'];
write2file(fileDataNew,convert2gcmfaces(fld2),dataprec);
end;

