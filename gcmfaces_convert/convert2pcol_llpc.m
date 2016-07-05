function [X,Y,FLD]=convert2pcol_llpc(x,y,fld,varargin);
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

%ASSEMBLE "LATLON" FACES:
%----------------------
X=[x{1};x{2};sym_g(x{3},7,0); sym_g(x{4},7,0)];
Y=[y{1};y{2};sym_g(y{3},7,0); sym_g(y{4},7,0)];
FLD=[fld{1}(:,:,k3,k4);fld{2}(:,:,k3,k4);sym_g(fld{3}(:,:,k3,k4),7,0);sym_g(fld{4}(:,:,k3,k4),7,0)];

%FIX DATE CHANGE LINE IN LATLON PART:
%--------------------------------------
X=circshift(X,[55 0]);
Y=circshift(Y,[55 0]);
FLD=circshift(FLD,[55 0]);

%ADD POINTS TO FIX DATE CHANGE LINE ELSEWHERE:
%---------------------------------------------
X=[X(353:end,:);X;X(1:32,:)];
Y=[Y(353:end,:);Y;Y(1:32,:)];
FLD=[FLD(353:end,:);FLD;FLD(1:32,:)];

tmp1=X(1:64,:); tmp1(tmp1>0)=tmp1(tmp1>0)-360; X(1:64,:)=tmp1;
tmp1=X(353:end,:); tmp1(tmp1<0)=tmp1(tmp1<0)+360; X(353:end,:)=tmp1;


