function []=m_map_gcmfaces_movie(dirFld,nameFld,varargin);

%check that m_map is in the path
aa=which('m_proj'); if isempty(aa); error('this function requires m_map that is missing'); end;

if ~isempty(strfind(nameFld,'ADJ'));  inadmod=1; else; inadmod=0; end;

choiceV3orV4='v4'

if ~isempty(choiceV3orV4)&isempty(whos('mygrid'));
  gcmfaces_global;
  dir0=[myenv.gcmfaces_dir '/sample_input/'];
  dirGrid=[dir0 'GRID' choiceV3orV4  '/'];
  if strcmp(choiceV3orV4,'v4'); nF=5; fileFormat='compact'; else; nF=1; fileFormat='straight'; end;
  grid_load(dirGrid,nF,fileFormat);
end;

dirOut=dirFld;
if nargin>2; k=varargin{1}; else; k=1; end;
if nargin>3; p=varargin{2}; else; p=0; end;
if nargin>4; cc=varargin{3}; else; cc=[]; end;

%set up directories:
dirCUR=pwd;
mkdir([dirOut 'movies/']);
mkdir([dirOut 'movies/TMP/']);
cd([dirOut 'movies/TMP/']);

%get the data:
fileList=dir([dirFld nameFld '*.data']);
%fileList=fileList(1:6:end);%skip some to go faster...
nt=length(fileList);
%tmp1=convert2array(mygrid.XC); [n1,n2]=size(tmp1);
%fld=convert2array(NaN*zeros(n1,n2,nt));
fld=NaN*mygrid.XC;
for tt=1:nt;
fld(:,:,tt)=read_bin([dirFld fileList(tt).name],1,k);
end;

mask=mygrid.hFacC; mask(find(mask==0))=NaN; mask(find(mask>0))=1;
if k>0; kk=k; else; kk=1; end;
mask=mask(:,:,kk); MASK=convert2array(mask);

%take out the first record, to visualize the model drift:
%fld0=fld(:,:,1); for tt=1:nt; fld(:,:,tt)=fld(:,:,tt)-fld0; end;

%caxis:
%cc=input('caxis? e.g. [0 1]\n');

%make movie:
%figure; set(gcf,'Units','Normalized','Position',[0.1 0.1 0.4 0.8]);
%figure; set(gcf,'Units','Normalized','Position',[0.1 0.1 0.8 0.8]);
figure; set(gcf,'Units','Normalized','Position',[0 0.1 0.4 0.4]);
nt=size(fld{1},3); %%%nt=10;
for tt=1:nt;
if tt<10; tt_txt='000'; elseif tt<100; tt_txt='00'; elseif tt<1000; tt_txt='0'; else; tt_txt=''; end; 
tt_txt=[tt_txt num2str(tt)];;
if inadmod==0; tt2=tt; else; tt2=nt-tt; end;
if tt2<10; tt2_txt='000'; elseif tt2<100; tt2_txt='00'; elseif tt2<1000; tt2_txt='0'; else; tt2_txt=''; end;
tt2_txt=[tt2_txt num2str(tt2)];;
m_map_gcmfaces(mask.*fld(:,:,tt),p,cc); title([nameFld ' ' tt2_txt],'Interpreter','none');
eval(['print -dtiff tmp_' nameFld '_' num2str(k) '_' tt_txt '.tiff']);
system(['convert tmp_' nameFld '_' num2str(k) '_' tt_txt '.tiff tmp_' nameFld '_' num2str(k) '_' tt_txt '.gif']);
end;
system(['gifsicle --delay=20 --loop tmp_' nameFld '_' num2str(k) '_*.gif  > ' nameFld '_' num2str(k) '.gif']);
delete(['tmp_' nameFld '_' num2str(k) '_*.tiff']);
delete(['tmp_' nameFld '_' num2str(k) '_*.gif']);

%handle files and dirs
movefile([nameFld '_' num2str(k) '.gif'] , '../.');
cd ..
%rmdir TMP
fprintf(['new movie >>>> ' dirFld '/movies/' nameFld '_' num2str(k) '.gif \n']); 
eval(['cd ' dirCUR ]);

