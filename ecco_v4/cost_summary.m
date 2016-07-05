function []=cost_summary(dir0,file0,cost0);
%object:	display summary of the various cost terms from costfunction0??? file
%input:		dir0 is the model run directory name
%          	file0 is the costfunction0??? file name (if '' then it will
%			be detected -- assuming there is only one in dir0)
%		cost0 is a reference value that will be used for normalization (1e8 by default)
%note:		hard coded ... mainly because multipliers are not in costfunction0??? file

if isempty(cost0); cost0=1e8; end;

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

%list of cost function terms and multipliers: (after apr1alpha/part2)
mylist={'fc','f_temp','f_salt','f_sst','f_tmi',...
   'argo_pacific_MITprof_latest_4mygridprof_T','argo_pacific_MITprof_latest_4mygridprof_S',...
   'argo_atlantic_MITprof_latest_4mygridprof_T','argo_atlantic_MITprof_latest_4mygridprof_S',...
   'argo_indian_MITprof_latest_4mygridprof_T','argo_indian_MITprof_latest_4mygridprof_S',...
   'seals_MITprof_latest_4mygridprof_T','seals_MITprof_latest_4mygridprof_S',...
   'WOD09_CTD_4mygridprof_T','WOD09_CTD_4mygridprof_S','WOD09_XBT_4mygridprof_T',...
   'area','area2sst','sshv4-mdt','sshv4-lsc',...
   'sshv4-tp','sshv4-ers','sshv4-gfo',...
   'sstv4-amsre-lsc','sstv4-amsre'};
mymult=[[0 0.15 0.15 2 2] [2 2 2 2 2 2 1 1 2 2 2] [0 50 200 40] 0.25*[1 1 1] 25 1];

%before apr1alpha part 2
%mylist={'fc','f_temp','f_salt','f_sst','f_tmi',...
%   'argo_pacific_MITprof_latest_4mygridprof_T','argo_pacific_MITprof_latest_4mygridprof_S',...
%   'argo_atlantic_MITprof_latest_4mygridprof_T','argo_atlantic_MITprof_latest_4mygridprof_S',...
%   'argo_indian_MITprof_latest_4mygridprof_T','argo_indian_MITprof_latest_4mygridprof_S',...
%   'seals_MITprof_latest_4mygridprof_T','seals_MITprof_latest_4mygridprof_S','XBT_v5_4mygridprof_T',...
%   'area','area2sst','sshv4-mdt','sshv4-lsc','sstv4-amsre-lsc',...
%   'sshv4-tp','sshv4-ers','sshv4-gfo','sstv4-amsre'};
%mymult0=[[0 0.5 0.5 1 1] [2 2 2 2 2 2 1 1 2] [2 50 10 10 10] [1 1 1 1]];%during no1beta part 4
%mymult1=[[0 0.15 0.15 1 1] [2 2 2 2 2 2 1 1 2] [1 50 100 20 50] 0.25*[1 1 1 1]];%during nov1beta part 5
%mymult=[[0 0.15 0.15 1 1] [2 2 2 2 2 2 1 1 2] [1 50 100 20 50] 0.25*[1 1 1 1]];%during apr1alpha/part1

%get cost from file (already in text form in memory):
mycost=[]; mycost2=[]; kk=0;
tmp1=[-3 strfind(tmp2,' ; ')]; 
for ii=1:length(tmp1)-1;
  tmp3=tmp2(tmp1(ii)+4:tmp1(ii+1));
  jj=strfind(tmp3,'='); jj=jj(end)+1; 
  tmp_name=tmp3(1:jj-2); tmp_val=tmp3(jj:end-1);
%
  jj=strfind(tmp_name,'gencost'); if ~isempty(jj); tmp_name=deblank(tmp_name(1:jj-2)); end;
  jj=find(~isspace(tmp_name)); tmp_name=tmp_name(jj);
  %if isempty(strfind(tmp_name,' prof_')); tmp_name=deblank(tmp_name); end;
%
  tmp_val(strfind(tmp_val,'D'))='e'; tmp_val(strfind(tmp_val,'+'))='';
  eval(['tmp_val=[ ' tmp_val ' ];']); tmp_val(tmp_val==0)=NaN;
%
  if ~isnan(tmp_val(1))&sum(strcmp(tmp_name,mylist))>0;
    tmp_mult=mymult(find(strcmp(tmp_name,mylist)));
    kk=kk+1;
    if kk==1; 
      mycost.name={tmp_name}; mycost.fc=tmp_val(1); mycost.no=tmp_val(2); mycost.mult=tmp_mult;
      mycost2.name=tmp_name; mycost2.fc=tmp_val(1); mycost2.no=tmp_val(2); mycost2.mult=tmp_mult;
    else; 
      mycost.name(kk)={tmp_name}; mycost.fc(kk)=tmp_val(1); mycost.no(kk)=tmp_val(2); mycost.mult(kk)=tmp_mult;
      mycost2(kk).name=tmp_name; mycost2(kk).fc=tmp_val(1); mycost2(kk).no=tmp_val(2); mycost2(kk).mult=tmp_mult;
    end;
  end;
end;

%check that I recover the total:
tmp1=100*sum(mycost.fc.*mycost.mult/mycost.fc(1));
fprintf('offline/online cost ratio is %3.3f%%\n',tmp1);

%share for each cost term:
myshare=mycost.fc.*mycost.mult; myshare=100*myshare/sum(myshare);
%groups of cost terms:
%myshare2=[sum(myshare(2:3)) sum(myshare([4 5 21 22])) sum(myshare(14:15)) sum(myshare([16:20])) sum(myshare(6:13))]';
fprintf('%15s   contributes %3.2f%% \n','T/S atlas',sum(myshare(2:3)));
fprintf('%15s   contributes %3.2f%% \n','SST',sum(myshare([4 5 24 25])));
fprintf('%15s   contributes %3.2f%% \n','ice conc',sum(myshare(17:18)));
fprintf('%15s   contributes %3.2f%% \n','SSH',sum(myshare(19:23)));
fprintf('%15s   contributes %3.2f%% \n','in situ',sum(myshare(6:16)));

%plot the various contributions:
%  myplot=myshare; aa=[0 1.5 0 length(myplot)+1];
%  figure; barh(myshare); axis(aa); grid on; hold on; title('cost terms contribution in %');
myplot=mycost.fc.*mycost.mult/cost0; aa=[0 10 0 length(myplot)+1];
myplot(1)=mycost.fc(1)/cost0; %to plot fc despite mult=0
figure; barh(myplot); axis(aa); grid on; hold on; title(sprintf('cost terms divided by %0.3g',cost0));
for ii=1:length(myplot); xx=myplot(ii)+0.01; yy=ii-0.4; text(xx,yy,mycost.name(ii),'Interpreter','none'); end;

