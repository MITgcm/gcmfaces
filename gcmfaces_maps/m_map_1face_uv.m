function []=m_map_1face_uv(fldU,fldV,iFace,varargin);
%purpose: 
%       use m_map to display one face in a chosen projection 
%syntax:
%       m_map_1face_uv(fldU,fldV,iFace,choiceProj);
%inputs:
%       fldU/fldV are uvel/vvel 2D fields in gcmfaces format
%       iFace is the face number
%       choiceProj is the projection choice (0, 1, 2, or 3)
%               if it is not stated, the default is mollweide (0)
%note:
%       the use of m_map/m_quiver.m is not advised since it distorts amplitudes
%       at the end of this routine, it is included only to document its syntax

%get grid data;
global mygrid;

if nargin>3; choicePlot=varargin{1}; else; choicePlot=0; end;
if nargin>4; scaleFac=varargin{2}; else; scaleFac=[]; end;
if nargin>5; subFac=varargin{3}; else; subFac=1;; end;

%check that m_map is in the path
aa=which('m_proj'); if isempty(aa); error('this function requires m_map that is missing'); end;
%set up projection using tracer function
m_map_1face(fldU*NaN,iFace,choicePlot); colorbar off;

%compute velocity at center point in east/north direction:
[fldUe,fldVn]=calc_UEVNfromUXVY(fldU,fldV);
x=mygrid.XC; y=mygrid.YC;
u=fldUe; v=fldVn;
%enforce [-180 180] longitude convention;
x(find(x>180))=x(find(x>180))-360;
%compute direction:
eps=1e-3;
[xp,yp]=m_ll2xy(x+eps*u,y+eps*v.*cos(y*pi/180),'clip','point');
[x,y]=m_ll2xy(x,y,'clip','point');
complexVec=(xp-x)+i*(yp-y); 
%scale amplitude
complexVec=complexVec./abs(complexVec).*abs(u+i*v);
%go back to reals:
u=real(complexVec); u(isnan(complexVec))=NaN;
v=imag(complexVec); v(isnan(complexVec))=NaN;
%select face:
x=x{iFace}; y=y{iFace};
u=u{iFace}; v=v{iFace};
%get rid of nans:
ii=1:subFac:size(x,1); jj=1:subFac:size(x,2);
x=x(ii,jj); y=y(ii,jj); u=u(ii,jj); v=v(ii,jj);
ii=find(~isnan(u.*v));
x=x(ii); y=y(ii); u=u(ii); v=v(ii);
%plot:
hold on; if isempty(scaleFac); quiver(x,y,u,v); else; quiver(x,y,u,v,scaleFac); end;

%syntax to use m_quiver.m
if 0;
[fldUe,fldVn]=calc_UEVNfromUXVY(fldU,fldV);
u=fldUe{iFace}; v=fldVn{iFace}; x=mygrid.XC{iFace}; y=mygrid.YC{iFace};
%get rid of nans:
ii=find(~isnan(u.*v)); ii=ii(1:subFac:end);
x=x(ii); y=y(ii); u=u(ii); v=v(ii);
%plot:
hold on; if isempty(scaleFac); m_quiver(x,y,u,v); else; m_quiver(x,y,u,v,scaleFac); end; 
return;
end;


