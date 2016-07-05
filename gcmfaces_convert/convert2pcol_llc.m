function [X,Y,FLD]=convert2pcol_llc(x,y,fld,varargin);
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
X=[x{1};x{2};sym_g(x{4},7,0); sym_g(x{5},7,0)];
Y=[y{1};y{2};sym_g(y{4},7,0); sym_g(y{5},7,0)];
FLD=[fld{1}(:,:,k3,k4);fld{2}(:,:,k3,k4);sym_g(fld{4}(:,:,k3,k4),7,0);sym_g(fld{5}(:,:,k3,k4),7,0)];

%ADD POLAR CAP:
%--------------
pp=x{3}; 
M1=pp; M1(M1>M1(1,1))=NaN; M1(M1<M1(1,end))=NaN; M1(~isnan(M1))=1;
%M1=NaN*pp;
%M2=pp; M2(M2<M2(1,1))=NaN; M2(M2>M2(end,1))=NaN; M2(~isnan(M2))=1;
M2=pp; M2(pp<0)=NaN; M2(pp>=0)=1;
M3=pp; M3(M3<M3(end,1)&M3>M3(end,end))=NaN; M3(~isnan(M3))=1;
%M3=NaN*pp;
%M4=pp; M4(M4<M4(end,end))=NaN; M4(M4>M4(1,end))=NaN; M4(~isnan(M4))=1;
M4=pp; M4(pp>=0)=NaN; M4(pp<0)=1;

pp=x{3}; Xp=[sym_g(pp.*M1,5,0);pp.*M2;sym_g(pp.*M3,7,0);sym_g(pp.*M4,6,0)]; X=[X Xp];
pp=y{3}; Yp=[sym_g(pp.*M1,5,0);pp.*M2;sym_g(pp.*M3,7,0);sym_g(pp.*M4,6,0)]; Y=[Y Yp];
pp=fld{3}(:,:,k3,k4); FLDp=[sym_g(pp.*M1,5,0);pp.*M2;sym_g(pp.*M3,7,0);sym_g(pp.*M4,6,0)]; FLD=[FLD FLDp];

%FIX DATE CHANGE LINE IN LATLON PART:
%--------------------------------------
s1=size(X); s1=round(s1(2)/2); s2=find(diff(X(:,s1))<-180); 
X=circshift(X,[-s2 0]);
Y=circshift(Y,[-s2 0]);
FLD=circshift(FLD,[-s2 0]);

%ADD POINTS TO FIX DATE CHANGE LINE ELSEWHERE:
%---------------------------------------------
s1=size(X); s1=round(s1(1)/12); 
tmp1=X(1:2*s1,:); tmp1(tmp1>0)=tmp1(tmp1>0)-360; X(1:2*s1,:)=tmp1;
tmp1=X(end-2*s1+1:end,:); tmp1(tmp1<0)=tmp1(tmp1<0)+360; X(end-2*s1+1:end,:)=tmp1;

X=[X-360;X;X+360]; Y=[Y;Y;Y]; FLD=[FLD;FLD;FLD];

