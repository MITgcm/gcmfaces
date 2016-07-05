function [cost]=cost_read(dir0,file0,list0);
%object:	read a cost function file such as costfunction0000
%input:		dir0 is the model run directory name
%          	file0 (optional) is the cost function file name (costfunction0000 or
%                  or costfunction0001 etc ). If file0 is not specified, 
%                  of specified as '' then it will be automatically be set
%                  by inspecting dir0 (assuming there is only one in dir0)
%               list0 (optional) is a cell array of cost term names
%output :       if list0 is NOT specified, then cost is a structure vector
%                  of cost(kk).fc, cost(kk).no, cost(kk).fc
%               if list0 is specified, then cost is the vector of cost terms

if isempty(who('file0')); file0=''; end;
if isempty(who('list0')); list0=''; end;

%take care of file name:
dir0=[dir0 '/'];
if isempty(file0);
  file0=dir([dir0 'costfunction0*']);
  if length(file0)>1&nargin>1; 
	fprintf('several costfunction0??? files were found:\n'); 
	{file0(:).name}'
	error('please be more specific');
  end;
  file0=file0.name;
end;
file0=[dir0 file0];

%read costfunction0??? file:
fid=fopen(file0); tmp2='';
while 1;
  tline = fgetl(fid);
  if ~ischar(tline), break, end
  if isempty(tmp2); tmp2=[tline ' ; ']; else; tmp2=[tmp2 ' ' tline ' ; ']; end;
end
fclose(fid);

%get cost from file (already in text form in memory):
cost=[]; cost2=[]; kk=0;
tmp1=[-3 strfind(tmp2,' ; ')]; 
for ii=1:length(tmp1)-1;
  tmp3=tmp2(tmp1(ii)+4:tmp1(ii+1));
  jj=strfind(tmp3,'='); jj=jj(end)+1; 
  tmp_name=tmp3(1:jj-2); tmp_val=tmp3(jj:end-1);
%
  tmp_val(strfind(tmp_val,'D'))='e'; tmp_val(strfind(tmp_val,'+'))='';
  eval(['tmp_val=[ ' tmp_val ' ];']); tmp_val(tmp_val==0)=NaN;
%
  if ~isnan(tmp_val(1));
    kk=kk+1;
    if kk==1; 
      cost.name=strtrim(tmp_name); cost.fc=tmp_val(1); cost.no=tmp_val(2);
    else; 
      cost(kk).name=strtrim(tmp_name); cost(kk).fc=tmp_val(1); cost(kk).no=tmp_val(2);
    end;
  end;
end;

%output vector of cost?
if ~isempty(list0);
  cost_bak=cost;
  nn=length(list0);
  cost=NaN*zeros(nn,1);
  list1={cost_bak(:).name};
  for kk=1:nn;
    jj=find(strcmp(list1,list0{kk}));
    if length(jj)>1;
      error([list0{kk} ' is not specific enough']);
    elseif length(jj)==1;
      %cost(kk,:)=[cost_bak(jj).fc cost_bak(jj).no]; 
      cost(kk)=cost_bak(jj).fc;
    end;
  end;
end;

