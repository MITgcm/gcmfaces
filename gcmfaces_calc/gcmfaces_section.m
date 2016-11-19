function [LO,LA,FLD,X,Y]=gcmfaces_section(lons,lats,fld,varargin);
%purpose: extract a great circle section (defined by two points) from a field
%         or a latitude circle (defined by one latitude)
%
%inputs:	lons/lats are the longitude/latitude vector
%		fld is the gcmfaces field (can incl. depth/time dimensions)
%optional:      sortByLon to sort point by longitude (default = 0 -> sort by latgitude) 
%outputs:	LO/LA is the vector of grid points longitude/latitude
%		FLD is the vector/matrix of grid point values (from fld)

gcmfaces_global;

if nargin>3; sortByLon=varargin{1}; else; sortByLon=0; end;

%check that LATS_MASKS has already been defined:
if ~isfield(mygrid,'LATS_MASKS');
    fprintf('one-time initialization of gcmfaces_lines_zonal: begin\n');
    gcmfaces_lines_zonal;
    fprintf('one-time initialization of gcmfaces_lines_zonal: end\n');
end;

if length(lats)==2;
    if lats(1)==-90&lats(2)==90; 
        error('need to specify latitude range under 180'); 
    end;
  line_cur=gcmfaces_lines_transp(lons,lats,{'tmp'});
elseif length(lats)==1;
  tmp1=abs(mygrid.LATS-lats);
  tmp2=find(tmp1==min(tmp1));
  tmp2=tmp2(1);
  line_cur=mygrid.LATS_MASKS(tmp2);
else;
  error('wrong specification of lons,lats');
end;
secP=find(line_cur.mskCedge==1);
secN=length(secP);

%lon/lat vectors:
LO=zeros(secN,1); LA=zeros(secN,1); 
%sections:
n3=max(size(fld{1},3),1); n4=max(size(fld{1},4),1); FLD=zeros(secN,n3,n4);
%counter:
ii0=0; 
for ff=1:secP.nFaces;
  tmp0=secP{ff}; [tmpI,tmpJ]=ind2sub(size(mygrid.XC{ff}),tmp0);
  tmp1=mygrid.XC{ff}; for ii=1:length(tmpI); LO(ii+ii0)=tmp1(tmpI(ii),tmpJ(ii)); end;
  tmp1=mygrid.YC{ff}; for ii=1:length(tmpI); LA(ii+ii0)=tmp1(tmpI(ii),tmpJ(ii)); end;
  tmp1=fld{ff}; for ii=1:length(tmpI); FLD(ii+ii0,:,:)=squeeze(tmp1(tmpI(ii),tmpJ(ii),:,:)); end;
  ii0=ii0+length(tmpI);
end;

%sort according to increasing latitude or longitude:
if sortByLon; 
  [tmp1,ii]=sort(LO); %sort according to increasing longitude
else;
  [tmp1,ii]=sort(LA); %sort according to increasing latitude
end;
LO=LO(ii); LA=LA(ii); FLD=FLD(ii,:,:);

%output axes for ploting with pcolor
nr=length(mygrid.RC);
nx=length(LO);
X=[]; Y=[];
if size(FLD,2)==nr&sortByLon; 
    X=LO'*ones(1,nr);
    Y=ones(nx,1)*mygrid.RC';
elseif size(FLD,2)==nr&~sortByLon;
    X=LA'*ones(1,nr);
    Y=ones(nx,1)*mygrid.RC';
elseif size(FLD,1)==nr&sortByLon; 
    X=LO';
    Y=ones(nx,1);
elseif size(FLD,2)==1&~sortByLon; 
    X=LA';
    Y=ones(nx,1);
end;
    
