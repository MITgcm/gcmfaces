function [varargout]=v4_basin(nameBasin,varargin);
%object:	obtain the mask of an ocean basin
%
%input:		nameBasin	name of the basin of interest (atl, pac, ind, arctic, etc.)
%optional:	msk0		value for the masked region (0 by default)
%
%output:	mskC		mask for tracer points (msk0=outside basin; 1=inside basin)
%optional:	mskW,mskS	mask for velocity points (0=oustide/land; 1/2=edge; 1=inside)

if nargin==2; msk0=varargin{1}; else; msk0=0; end;

gcmfaces_global;

if ~isempty(which('v4_basin.bin'));
  msk=read_bin('v4_basin.bin',0,1);
else;%try old name and location
  dir0=which('gcmfaces_demo');
  tmp1=strfind(dir0,filesep); 
  dir0=[dir0(1:tmp1(end)) 'sample_input/OCCAetcONv4GRID/'];
  fil0='basin_masks_eccollc_90x50.bin';
  if isempty(dir([dir0 fil0]));
    warning(['v4_basin requires ' fil0 ' that was not found ---> skip v4_basin!']);
    varargout={[]};
    return;
  end;
  msk=read_bin([dir0 'basin_masks_eccollc_90x50.bin'],0,1);
end;

%list of available basins:
list0={	'pac','atl','ind','arct','bering',...
        'southChina','mexico','okhotsk','hudson','med',...
        'java','north','japan','timor','eastChina','red','gulf',...
        'baffin','gin','barents'};
%list of selected basins:
if ischar(nameBasin); nameBasin={nameBasin}; end;
list1={};
for ii=1:length(nameBasin);
  if strcmp(nameBasin{ii},'atlExt');
    list1={list1{:},'atl','mexico','hudson','med','north','baffin','gin'};
  elseif strcmp(nameBasin{ii},'pacExt');
    list1={list1{:},'pac','bering','okhotsk','japan','eastChina'};
  elseif strcmp(nameBasin{ii},'indExt');
    list1={list1{:},'ind','southChina','java','timor','red','gulf'};
  else;
    list1={list1{:},nameBasin{ii}};
  end;
end 

%derive tracer points mask:
mskC=0*msk;
for ii=1:length(list1);
  jj=find(strcmp(list1{ii},list0));
  if ~isempty(jj); mskC(find(msk==jj))=1; end;
end;

%determine velocity points masks, if needed:
if nargout>1;
  %flag velocity points according to neighboring pair: 
  fld=3*mskC+1*(~isnan(mygrid.mskC(:,:,1)));
  FLD=exch_T_N(fld);
  fldW=fld; fldS=fld;
  for iF=1:FLD.nFaces;
     tmpA=FLD{iF}(2:end-1,2:end-1);
     tmpB=FLD{iF}(1:end-2,2:end-1);
     fldW{iF}=(tmpA+tmpB)/2;
     tmpA=FLD{iF}(2:end-1,2:end-1);
     tmpB=FLD{iF}(2:end-1,1:end-2);
     fldS{iF}=(tmpA+tmpB)/2;
  end;
  %compute corresponding masks:
  mskW=0*mskC;
  mskW(find(fldW==4))=1;%inside points
  mskW(find(fldW==2.5))=0.5;%basin edge points
  mskS=0*mskC; 
  mskS(find(fldS==4))=1;%inside points
  mskS(find(fldS==2.5))=0.5;%basin edge points
  %for checking:
  if 0;
  mskWout=0*mskC;
  mskWout(find(fldW==1))=1;%outside points
  mskWout(find(fldW==2.5))=0.5;%basin edge points
  mskSout=0*mskC;
  mskSout(find(fldS==1))=1;%outside points
  mskSout(find(fldS==2.5))=0.5;%basin edge points
  end;
end;

%replace 0 with msk0:
mskC(find(mskC==0))=msk0;
if nargout>1; mskW(find(mskW==0))=msk0; mskS(find(mskS==0))=msk0; end;

%output(s):
if nargout==1; varargout={mskC}; else; varargout={mskC,mskW,mskS}; end;

%for checking:
if 0;
figure;
msk0=1*(msk0>0); msk0(find(msk0==0))=NaN;
subplot(2,1,1); imagescnan(convert2array(msk0)'); axis xy; caxis([-1 2]);
subplot(2,1,2); imagescnan(convert2array(mskC.*msk0)'); axis xy; caxis([-1 2]);  
drawnow;
end;


