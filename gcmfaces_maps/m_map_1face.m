function []=m_map_1face(fld,iFace,varargin);
%purpose: 
%	use m_map to display one face in a chosen projection 
%synthax:
%	m_map_1face(fld,iFace,choiceProj);
%inputs:
%	fld is a 2D field in gcmfaces format
%	iFace is the face number
%	choiceProj is the projection choice (0, 1, 2, or 3)
%		if it is not stated, the default is mollweide (0)

%check that m_map is in the path
aa=which('m_proj'); if isempty(aa); error('this function requires m_map that is missing'); end; 

%get parameters:
if nargin>2; choiceProj=varargin{1}; else; choiceProj=0; end;
if nargin>3; cc=varargin{2}; else; cc=[]; end;
if nargin>4; doPlotCoast=varargin{3}; else; doPlotCoast=1; end;

global mygrid;

%extract face:
x=mygrid.XC{iFace}(:,:);
y=mygrid.YC{iFace}(:,:);
z=fld{iFace}(:,:);
m1=mygrid.mskC{iFace}(:,:,1);
if length(size(z))~=2; error('input must be a 2D field in gcmfaces format'); end;

%put mask on x and y:
x(isnan(m1))=NaN; y(isnan(m1))=NaN;

%enforce [-180 180] longitude convention;
x(find(x>180))=x(find(x>180))-360;

%select lat/lon range:
ii=find(~isnan(m1));
ll=[min(x(ii)) max(x(ii))]; 
LL=[min(y(ii)) max(y(ii))];

if choiceProj==0;
%%m_proj('Miller Cylindrical','lon',ll,'lat',LL);
%%m_proj('Equidistant cylindrical','lon',ll,'lat',LL);
m_proj('mollweide','lon',ll,'lat',LL);
elseif choiceProj==1;
m_proj('Mercator','lon',ll,'lat',LL);
elseif choiceProj==2;
m_proj('Stereographic','lon',0,'lat',90,'rad',90-LL(1));
elseif choiceProj==3;
m_proj('Stereographic','lon',0,'lat',-90,'rad',90+LL(2) );
end;

[x,y]=m_ll2xy(x,y);
pcolor(x,y,z); shading flat; if ~isempty(cc); caxis(cc); end; colorbar;
if doPlotCoast; m_coast('patch',[1 1 1]*.7,'edgecolor','none'); end; m_grid;


