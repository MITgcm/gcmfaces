function [flt,data,header] = flt_traj_read(varargin)
% Reads the float_trajectories files.
%
% flts=flt_traj_read(File_Names,[Worldlength],[FloatList]);
%
% inputs: File_Names is a file name
%         Worldlength (= 4 or 8) is optional
%         FloatList (= a subset of [1:n] where n is the number of floats) is the second optional argument
%
% output: flt is a structured array with fields 'time','x','y','k','u','v','t','s','p'
%         data (optional) is an array of all data points (concatenated 13x1 vectors)
%         header (optional) summarizes all output times (concatenated 13x1 vectors)
%         
% Example:
% >> [flt,data,header]=flt_traj_read('float_trajectories',4);
% >> plot( flts(3).time, flts(3).x/1e3 )
% >> for k=1:126;plot(flts(k).x/1e3,flts(k).y/1e3);hold on;end;hold off

fName = varargin{1};
imax=13;                  % record size
ieee='b';                 % IEEE big-endian format
WORDLENGTH = 8;           % 8 bytes per real*8
if nargin>=2
   WORDLENGTH = varargin{2};
end
bytesPerRec=imax*WORDLENGTH;
rtype =['real*',num2str(WORDLENGTH)];
if nargin==3;
   list_flt=varargin{3};
else;
   list_flt=[];
end;

[I]=strfind(fName,filesep);
if length(I) == 0,
 bDr='';
else
 fprintf(' Found filesep in file name (at');
 fprintf(' %i',I);
 bDr=fName(1:I(end));
 fprintf(' ) ; will load files from: \n  "%s"\n',bDr);
end

%% Read everything

fls=dir([fName,'.*data']);

i1=[fls(:).bytes]/bytesPerRec;
i2=cumsum(i1-1);
i1=[1 i2(1:end-1)+1];

data=zeros(imax,i2(end));
header=zeros(imax,length(fls));

tic;
for k=1:size(fls,1)
 fid=fopen([bDr,fls(k).name],'r',ieee);
 header(:,k)=fread(fid,[imax 1],rtype);
 data(:,i1(k):i2(k))=fread(fid,[imax i2(k)-i1(k)+1],rtype);
 tmp1=fread(fid,1,rtype); if ~feof(fid); error('incomplete read'); end;
 fclose(fid);
end
toc;

%% Sort data according to time then float ID

tic;
[t,jj]=sort( data(2,:) ); data=data(:,jj);
[t,jj]=sort( data(1,:) ); data=data(:,jj);
[C,IA,IC] = unique(data(1,:));
j1=IA; j2=[IA(2:end);size(data,1)];
toc;

%% Initialize flt

tic;
flt=struct('numsteps',[],'time',[],'x',[],'y',[],'z',[]);
nflt=max(max(data(1,:)));
if isempty(list_flt); list_flt=[1:nflt]; end;
nflt=length(list_flt);
flt=repmat(flt,[1 nflt]);
toc;

%% Extract selected floats

tic;
for k=1:nflt;
 tmp=data(:,j1(list_flt(k)):j2(list_flt(k)));
 flt(k).time=tmp(2,:);
 flt(k).x=tmp( 3,:);
 flt(k).y=tmp( 4,:);
 flt(k).z=tmp( 5,:);
 flt(k).i=tmp( 6,:);
 flt(k).j=tmp( 7,:);
 flt(k).k=tmp( 8,:);
 flt(k).p=tmp( 9,:);
 flt(k).u=tmp(10,:);
 flt(k).v=tmp(11,:);
 flt(k).t=tmp(12,:);
 flt(k).s=tmp(13,:); 
end;
toc;

return

