function []=m_map_gcmfaces_uv(fldU,fldV,varargin);

global mygrid;

if nargin>2; choicePlot=varargin{1}; else; choicePlot=0; end;
if nargin>3; scaleFac=varargin{2}; else; scaleFac=[]; end;
if nargin>4; subFac=varargin{3}; else; subFac=1;; end;

[fldUe,fldVn]=calc_UEVNfromUXVY(fldU,fldV);

if choicePlot==-1;
%%m_proj('Miller Cylindrical','lat',[-90 90]);
%%m_proj('Equidistant cylindrical','lat',[-90 90]);
m_proj('mollweide','lon',[-180 180],'lat',[-89 89]);
%m_proj('mollweide','lon',[-100 20],'lat',[0 70]);

[uu,vv]=m_map_gcmfaces_uvrotate(fldUe,fldVn);
[xx,yy,u]=convert2pcol(mygrid.XC,mygrid.YC,uu);
[xx,yy,v]=convert2pcol(mygrid.XC,mygrid.YC,vv);
[x,y]=m_ll2xy(xx,yy);

%ger rid of nans and subsample:
ii=find(~isnan(u.*v)); ii=ii(1:subFac:end);
x=x(ii); y=y(ii); u=u(ii); v=v(ii);
m_coast('patch',[1 1 1]*.7,'edgecolor','none'); m_grid;
hold on; if isempty(scaleFac); quiver(x,y,u,v); else; quiver(x,y,u,v,scaleFac); end;
end;%if choicePlot==0|choicePlot==1; 

if choicePlot==0; subplot(2,1,1); end;
if choicePlot==0|choicePlot==1; 
m_proj('Mercator','lat',[-70 70]);

[uu,vv]=m_map_gcmfaces_uvrotate(fldUe,fldVn);
[xx,yy,u]=convert2pcol(mygrid.XC,mygrid.YC,uu);
[xx,yy,v]=convert2pcol(mygrid.XC,mygrid.YC,vv);
[x,y]=m_ll2xy(xx,yy);

%ger rid of nans and subsample:
ii=find(~isnan(u.*v)); ii=ii(1:subFac:end);
x=x(ii); y=y(ii); u=u(ii); v=v(ii);
m_coast('patch',[1 1 1]*.7,'edgecolor','none'); m_grid;
hold on; if isempty(scaleFac); quiver(x,y,u,v); else; quiver(x,y,u,v,scaleFac); end;
end;%if choicePlot==0|choicePlot==1; 

if choicePlot==0; subplot(2,2,3); end;
if choicePlot==0|choicePlot==2; 
m_proj('Stereographic','lon',0,'lat',90,'rad',40);

[uu,vv]=m_map_gcmfaces_uvrotate(fldUe,fldVn);
xx=convert2arctic(mygrid.XC,0);
yy=convert2arctic(mygrid.YC,0);
u=convert2arctic(uu);
v=convert2arctic(vv);
[x,y]=m_ll2xy(xx,yy);

%ger rid of nans and subsample:
ii=find(~isnan(u.*v)); ii=ii(1:subFac:end);
x=x(ii); y=y(ii); u=u(ii); v=v(ii);
m_coast('patch',[1 1 1]*.7,'edgecolor','none'); m_grid;
hold on; if isempty(scaleFac); quiver(x,y,u,v); else; quiver(x,y,u,v,scaleFac); end;
end;%if choicePlot==0|choicePlot==1; 

if choicePlot==0; subplot(2,2,4); end;
if choicePlot==0|choicePlot==3; 
m_proj('Stereographic','lon',0,'lat',-90,'rad',40);

[uu,vv]=m_map_gcmfaces_uvrotate(fldUe,fldVn);
xx=convert2southern(mygrid.XC,0);
yy=convert2southern(mygrid.YC,0);
u=convert2southern(uu);
v=convert2southern(vv);
[x,y]=m_ll2xy(xx,yy);

%ger rid of nans and subsample:
ii=find(~isnan(u.*v)); ii=ii(1:subFac:end);
x=x(ii); y=y(ii); u=u(ii); v=v(ii);
m_coast('patch',[1 1 1]*.7,'edgecolor','none'); m_grid;
hold on; if isempty(scaleFac); quiver(x,y,u,v); else; quiver(x,y,u,v,scaleFac); end;
end;%if choicePlot==0|choicePlot==1; 



