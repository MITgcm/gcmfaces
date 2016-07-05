function [report0]=diff_mat(file1,dir2,varargin);
%object:	compute the %rms difference between fields in two mat files
%inputs:	file1 is the file to compare with a reference
%		dir2 is the reference file directory 
%optional:	file2 is the reference file (file1 by default)
%output:	cell array containing the % rms difference display per field

if nargin>2; file2=varargin{1}; else; file2=file1; end;

new=open(file1); old=open([dir2 file2]);

%new list of fields:
%===================
IInew=fieldnames(new); NInew=length(IInew);
%extend to structure fields:
JJ={};
for ii=1:NInew;
  tmp0=IInew{ii}; tmp1=getfield(new,tmp0);
  if isstruct(tmp1);
    tmp2=fieldnames(tmp1);
    for jj=1:length(tmp2); JJ{length(JJ)+1}=[tmp0 '.' tmp2{jj}]; end;
  else;
    JJ{length(JJ)+1}=tmp0;
  end;
end;
%overwrite list of fields:
IInew=JJ; NInew=length(IInew);

%old list of fields:
%===================
IIold=fieldnames(old); NIold=length(IIold);
%extend to structure fields:
JJ={};
for ii=1:NIold;
  tmp0=IIold{ii}; tmp1=getfield(old,tmp0);
  if isstruct(tmp1);
    tmp2=fieldnames(tmp1);
    for jj=1:length(tmp2); JJ{length(JJ)+1}=[tmp0 '.' tmp2{jj}]; end;
  else;
    JJ{length(JJ)+1}=tmp0;
  end;
end;
%overwrite list of fields:
IIold=JJ; NIold=length(IIold);

%compare new to old fields:
%==========================
report0={};
report1={};
for ii=1:NInew;
  test0=isempty(find(strcmp(IIold,IInew{ii})));
  test1=strfind(IInew{ii},'gcm2faces');
  if test0; 
    txt0=sprintf(['new contains ' IInew{ii} ' BUT ref does not']);
    report1{length(report1)+1,1}=txt0;
  elseif test1;
    txt0=sprintf(['test of ' IInew{ii} ' was omitted']);
    report1{length(report1)+1,1}=txt0;
  else;
    tmp0=IInew{ii}; tmp00=strfind(tmp0,'.');
    if isempty(tmp00); 
      %get the field:
      tmp1=getfield(new,IInew{ii}); tmp2=getfield(old,IInew{ii});
    elseif length(tmp00)==1;
      %get the sub field:
      tmp11=IInew{ii}(1:tmp00-1);
      tmp1=getfield(new,tmp11); tmp2=getfield(old,tmp11);
      tmp11=IInew{ii}(tmp00+1:end);
      tmp1=getfield(tmp1,tmp11); tmp2=getfield(tmp2,tmp11);
    else;
      error(sprintf('cannot compare %s',tmp0));
    end;
    %do the comparison:
    if isa(tmp1,'double')|isa(tmp1,'gcmfaces');
      %add blanks for display:
      tmp11=ceil(length(tmp0)/10)*10-length(tmp0); tmp11=char(32*ones(1,tmp11));
      %compute difference:
      tmp22=nanstd(tmp1(:))^2; if tmp22==0; tmp22=nanmean( tmp1(:).^2 ); end;
      tmp22=100*sqrt(nanmean( (tmp1(:)-tmp2(:)).^2 )./tmp22);
      %full text for display:
      txt0=[tmp0 tmp11];
      %txt0=sprintf('%s differs by  %i%%  from %s',txt0,round(tmp22),[dir2 file2]);
      txt0=sprintf('%s diff by  %i%%',txt0,round(tmp22));
      %do display:
      if tmp22~=0; fprintf([txt0 '\n']); end; 
      %add to report:
      report0{length(report0)+1,1}=txt0;
    end;
  end;
end;

%compare old field to new fields:
%================================
report2={};
for ii=1:NIold;
  test0=~isempty(find(strcmp(IInew,IIold{ii})));
  if ~test0;
    txt0=sprintf(['ref contains ' IIold{ii} ' BUT new does not']);
    report2{length(report2)+1,1}=txt0;
  end;
end;

%combine the various reports:
%============================
report0={report0{:} report1{:}}';
report0={report0{:} report2{:}}';

