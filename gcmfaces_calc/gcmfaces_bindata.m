function [varargout]=gcmfaces_bindata(varargin);
%object:    compute delaunay triangulation, then bin averaging
%inputs:    are all optional, triggering different sections of the code
%   if   none          then generate the very triangulation (myTri)
%   if   lon,lat       vectors, then compute closest neighbor index(ices)
%   if   lon,lat,obs   vectors, then further do the bin average
%outputs:   are all optional, triggering different sections of the code
%   if   OBS            then return the bin aberage
%   if   OBS,NOBS       then return the bin sum and count
%
%pre-requisite : the grid of interest must have been loaded with grid_load
%
%note to self: should mytri become part of mygrid ?

warning('off','MATLAB:dsearch:DeprecatedFunction');

gcmfaces_global; global mytri;

if ~isfield(myenv,'useDelaunayTri');
    myenv.useDelaunayTri=~isempty(which('DelaunayTri'));
end;

%1) check that triangulation is up to date
if isempty(mytri);
  mytri.dirGrid=mygrid.dirGrid; mytri.nFaces=mygrid.nFaces;
  mytri.fileFormat=mygrid.fileFormat; mytri.ioSize=mygrid.ioSize;
end;

test1=strcmp(mytri.dirGrid,mygrid.dirGrid)&(mytri.nFaces==mygrid.nFaces)&...
      strcmp(mytri.fileFormat,mygrid.fileFormat)&(sum(mytri.ioSize~=mygrid.ioSize)==0);
test2=isfield(mytri,'TRI');

%2) update triangulation if not up to date
if (~test1|~test2)&(nargin~=0); gcmfaces_bindata; end;

%3) carry on depending on inputs list
if (nargin==0);
    %
    mytri=[];
    mytri.dirGrid=mygrid.dirGrid; mytri.nFaces=mygrid.nFaces;
    mytri.fileFormat=mygrid.fileFormat; mytri.ioSize=mygrid.ioSize;
    %generate delaunay triangulation:
    XC=convert2array(mygrid.XC);
    YC=convert2array(mygrid.YC);
    kk=find(~isnan(XC)); mytri.kk=kk;
    [mytri.ii,mytri.jj]=find(~isnan(XC));
    if myenv.useDelaunayTri;
        %the new way, using DelaunayTri&nearestNeighbor
        mytri.TRI=DelaunayTri(XC(kk),YC(kk));
    else;
        %the old way, using delaunay&dsearch
        TRI=delaunay(XC(kk),YC(kk)); nxy = length(kk);
        Stri=sparse(TRI(:,[1 1 2 2 3 3]),TRI(:,[2 3 1 3 1 2]),1,nxy,nxy);
        mytri.XC=XC(mytri.kk); mytri.YC=YC(mytri.kk); 
        mytri.TRI=TRI; mytri.Stri=Stri;
        %usage: kk=dsearch(mytri.XC,mytri.YC,mytri.TRI,lon,lat,mytri.Stri);
        %	where lon and lat are vector of position
    end
elseif nargin==2;
    %compute grid point vector associated with lon/lat vectors
    lon=varargin{1}; lat=varargin{2};
    if size(lon,2)>1; lon=lon'; end;
    if size(lat,2)>1; lat=lat'; end;
    if myenv.useDelaunayTri;
        if size(lon,2)>1; lon=lon'; lat=lat'; end;
        kk = mytri.TRI.nearestNeighbor(lon,lat);
    else;
        kk=dsearch(mytri.XC,mytri.YC,mytri.TRI,lon,lat,mytri.Stri);
    end;
    if nargout==1;
        varargout={mytri.kk(kk)};
    elseif nargout==2;
        ii=mytri.ii(kk); jj=mytri.jj(kk);
        varargout={ii}; varargout(2)={jj};
    else;
        error('wrong output choice');
    end;
elseif nargin==3;
    %do the bin average (if nargout==1) or the bin sum+count (if nargout==2)
    lon=varargin{1}; lat=varargin{2}; obs=varargin{3};
    if size(lon,2)>1; lon=lon'; end;
    if size(lat,2)>1; lat=lat'; end;
    if size(obs,2)>1; obs=obs'; end;
    ii=find(~isnan(obs)); lon=lon(ii); lat=lat(ii); obs=obs(ii);
    if myenv.useDelaunayTri;
        kk = mytri.TRI.nearestNeighbor(lon,lat);
    else;
        kk=dsearch(mytri.XC,mytri.YC,mytri.TRI,lon,lat,mytri.Stri);
    end;
    kk=mytri.kk(kk);
    
    OBS=convert2array(mygrid.XC); 
    OBS(:)=0; NOBS=OBS;
    for k=1:length(kk)
        NOBS(kk(k))=NOBS(kk(k))+1;
        OBS(kk(k))=OBS(kk(k))+obs(k);
    end  % k=1:length(kk)
    
    if nargout==1;%output bin average
        in=find(NOBS); OBS(in)=OBS(in)./NOBS(in);
        in=find(~NOBS); OBS(in)=NaN; NOBS(in)=NaN;
        varargout={convert2array(OBS)};
    elseif nargout==2;%output bin sum+count
        OBS=convert2array(OBS);
        NOBS=convert2array(NOBS);
        varargout={OBS}; varargout(2)={NOBS};
    else;
        error('wrong output choice');
    end;
    
else;
    error('wrong input choice');
end;

warning('on','MATLAB:dsearch:DeprecatedFunction');



