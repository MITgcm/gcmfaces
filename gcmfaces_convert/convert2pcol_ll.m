function [X,Y,FLD]=convert2pcol_ll(x,y,fld,varargin);
%object:    gcmfaces to 'pcolor format' conversion
%inputs:    x is longitude (e.g. mygrid.XC)
%           y is latitude (e.g. mygrid.YC)
%           fld is the 2D field of interest (e.g. mygrid.hFacC(:,:,1))
%outputs:   X,Y,FLD are array versions of x,y,fld
%
%note:      this function is designed so that one may readily
%           plot the output in geographic coordinates
%           using e.g. 'figure; pcolor(X,Y,FLD);'

k3=1; k4=1;

global regularizeXC;
if isempty(regularizeXC);
fprintf('\n\nconvert2pcol_ll.m init: by default gcmfaces assumes\n');
fprintf('   that XC is longitude in the [-180 180] range, and \n');
fprintf('   if XC shows values outside this range, gcmfaces \n');
fprintf('   will to enforce this convention in graphs. If this is \n');
fprintf('   inadequate, you may try to set regularizeXC to 0 below \n\n');
regularizeXC=1;
end;

%ASSEMBLE "LATLON" FACES:
%----------------------
X=x{1}; Y=y{1}; FLD=fld{1}(:,:,k3,k4);

%FIX DATE CHANGE LINE IN LATLON PART:
%--------------------------------------
if regularizeXC;
  ii=max(find(X(:,1)<=180)); 
  X=circshift(X,[-ii 0]); X(X>180)=X(X>180)-360; 
  Y=circshift(Y,[-ii 0]);
  FLD=circshift(FLD,[-ii 0]);
end;

