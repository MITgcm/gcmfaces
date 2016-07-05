function [alldiag]=alldiag_load(dirMat,nameMat,varargin);
%object:	load single record files off basic_diags_ecco, and assemble time records
%inputs:	dirMat is the model run sub-directory where the matlab files are (e.g. 'mat/')
%           nameMat is the mat files name (e.g. 'basic_diags_ecco_A_*.mat')
%optional:  nameDiag is the name of the diagnostic of interest
%           subListTimes is a vector to reduce listTimes to listTimes(subListTimes)

if nargin>2; nameDiag=varargin{1}; else; nameDiag=''; end;
if nargin>3; subListTimes=varargin{2}; else; subListTimes=[]; end;

%model run paramters (from basic_diags_ecco_mygrid.mat)
global myparms;

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
alldiag=load([dirMat listFiles(1).name]);
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
  alldiag=load([dirMat listFiles(1).name]);
end;
%extend time dimension
listNdim=ones(1,length(listDiags));
listTT={};
listDD='';
for ii=1:length(listDiags);
  %list diags in text string
  listDD=[listDD listDiags{ii} ''','''];
  %get data: 
  eval(['tmp1=alldiag.' listDiags{ii} ';']);
  %determine the time dimension:
  if strcmp(class(tmp1),'gcmfaces'); nDim=size(tmp1{1}); else; nDim=size(tmp1); end;
  if ~isempty(find(nDim==0)); nDim=0;
  elseif nDim(end)==1; nDim=length(nDim)-1;
  else; nDim=length(nDim);
  end;
  %store nDim for use below
  listNdim(ii)=nDim;
  tt=''; for jj=1:nDim; tt=[tt ':,']; end; 
  listTT{ii}=['(' tt 'tt)'];
  %extend time dimension:
  if nDim>0;
    tmp2=ones(1,nDim+1); tmp2(end)=length(listSteps);
    tmp2=repmat(tmp1,tmp2); 
    eval(['alldiag.' listDiags{ii} '=tmp2;']);
  end;
end;
%finalize text-list of variables to load
listDD=['''' listDD(1:end-2)];
%loop and concatenate
for tt=2:length(listSteps);
   eval(['tmpdiag=load([dirMat listFiles(tt).name],' listDD  ');']);
   for ii=1:length(listDiags);
     nDim=listNdim(ii);
     if nDim>0; 
       eval(['alldiag.' listDiags{ii} listTT{ii} '=tmpdiag.' listDiags{ii} ';']);
     end;
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
%squeeze
for ii=1:length(alldiag.listDiags);
eval(['alldiag.' listDiags{ii} '=squeeze(alldiag.' listDiags{ii} ');']);
end;

