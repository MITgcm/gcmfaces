function [alldiag]=diags_read_from_mat(dirMat,nameMat,varargin);
%object:	load single record files off basic_diags_ecco, and assemble time records
%inputs:	dirMat is the model run sub-directory where the matlab files are (e.g. 'mat/')
%           nameMat is the mat files name (e.g. 'basic_diags_ecco_A_*.mat')
%optional:  nameDiag is the name of the diagnostic of interest
%           subListTimes is a vector to reduce listTimes to listTimes(subListTimes)

if nargin>2; nameDiag=varargin{1}; else; nameDiag=''; end;
if nargin>3; subListTimes=varargin{2}; else; subListTimes=[]; end;

%model run paramters (from basic_diags_ecco_mygrid.mat)
gcmfaces_global; global myparms;

if isempty(myparms)|isempty(mygrid);
  if ~isempty(dir([dirMat 'diags_grid_parms.mat'])); 
    load([dirMat 'diags_grid_parms.mat']);
  elseif ~isempty(dir([dirMat '../diags_grid_parms.mat']));
    load([dirMat '../diags_grid_parms.mat']);
  else;
    error('could not find diags_grid_parms.mat');
  end;
end;

%get list of files
listFiles=dir([dirMat '/' nameMat]);
%get time steps and sort listFiles 
listSteps=[]; for tt=1:length(listFiles); 
nn=listFiles(tt).name; ii=strfind(nn,'_'); ii=ii(end); listSteps=[listSteps;str2num(nn(ii+1:end-4))]; end;
[listSteps,ii]=sort(listSteps);
listFiles=listFiles(ii);
%compute approximate times (in years -- using 365.25 as year length)
listTimes=myparms.yearFirst(1)+listSteps*myparms.timeStep/86400/365.25;
%initialize alldiag
alldiag=open([dirMat listFiles(1).name]);
listDiags=fieldnames(alldiag);
%restrict list of diags to load
if ~isempty(nameDiag);
  if iscell(nameDiag); listDiags=nameDiag;
  else; listDiags={nameDiag};
  end;
end;
%restrict list of times
if ~isempty(subListTimes); 
  listSteps=listSteps(subListTimes);
  listTimes=listTimes(subListTimes);
  listFiles=listFiles(subListTimes);
  alldiag=open([dirMat listFiles(1).name]);
end;
%loop and concatenate
for tt=2:length(listSteps);
   tmpdiag=open([dirMat listFiles(tt).name]);
   for ii=1:length(listDiags);
     %get data: 
     eval(['tmp1=tmpdiag.' listDiags{ii} '; tmp2=alldiag.' listDiags{ii} ';']); 
     %fix loaded objects if needed:
     if isa(tmp1,'gcmfaces'); tmp1=matLoadFix(tmp1); end;
     if isa(tmp2,'gcmfaces'); tmp2=matLoadFix(tmp2); end;
     %determine the time dimension:
     if isa(tmp1,'gcmfaces'); nDim=size(tmp1{1}); else; nDim=size(tmp1); end; 
     if ~isempty(find(nDim==0)); nDim=0;
     elseif nDim(end)==1; nDim=length(nDim)-1;
     else; nDim=length(nDim);
     end;
     %concatenate along the time dimension:
     if nDim>0; tmp2=cat(nDim+1,tmp2,tmp1); eval(['alldiag.' listDiags{ii} '=tmp2;']); end;
   end;
end;
%clean empty diags up
for ii=1:length(listDiags);
  eval(['tmp1=isempty(alldiag.' listDiags{ii} ');']);
  if tmp1; alldiag=rmfield(alldiag,listDiags{ii}); end;
end;
%remove diags that were not selected (and therefore not concatenated)
tmpDiags=fieldnames(alldiag);
for ii=1:length(tmpDiags);
  if ~sum(sum(strcmp(tmpDiags{ii},listDiags))); alldiag=rmfield(alldiag,tmpDiags{ii}); end;
end;
%complement alldiag
alldiag.listSteps=listSteps;
alldiag.listTimes=listTimes;
alldiag.listDiags=listDiags;

