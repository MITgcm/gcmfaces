function [xx,yy]=gcmfaces_stereoproj(XC0,YC0,XC,YC);
%[xx,yy]=gcmfaces_stereoproj(XC0,YC0);
%object:    compute stereographic projection putting XC0,YC0 at 0,0
%inputs:    XC0,YC0 are the origin longitude,latitude
%(optional) XC,YC are the lon,lat points to project (XC,YC by default)
%outputs:   xx,yy are the projected points

%for additional information see :
% http://www4.ncsu.edu/~franzen/public_html/CH795Z/math/lab_frame/lab_frame.html
% http://physics.unm.edu/Courses/Finley/p503/handouts/SphereProjectionFINALwFig.pdf

gcmfaces_global;

if isempty(who('XC'))|isempty(who('YC'));
    XC=mygrid.XC; YC=mygrid.YC;
end;

%compute spherical coordinates:
phi=pi/180*XC; theta=pi/180*(90-YC);
phi0=pi/180*XC0; theta0=pi/180*(90-YC0);

%compute cartesian coordinates:
X=sin(theta).*cos(phi);
Y=sin(theta).*sin(phi);
Z=cos(theta);

x=X; y=Y; z=Z;

%bring chosen point to the north pole:
xx=x; yy=y; zz=z;
x=cos(phi0)*xx+sin(phi0)*yy;
y=-sin(phi0)*xx+cos(phi0)*yy;
z=zz;
%
xx=x; yy=y; zz=z;
x=cos(theta0)*xx-sin(theta0)*zz;
y=yy;
z=sin(theta0)*xx+cos(theta0)*zz;

%stereographic projection from the south pole:
xx=x./(1+z);
yy=y./(1+z);

% nrm=sqrt(xx.^2+yy.^2); 
% msk=1+0*nrm; msk(nrm>tan(pi/4/2))=NaN;%mask points outside of pi/4 cone

