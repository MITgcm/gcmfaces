function [fldUm,fldVm]=m_map_gcmfaces_uvrotate(fldUe,fldVn);  

%check that m_map is in the path
aa=which('m_proj'); if isempty(aa); error('this function requires m_map that is missing'); end;

global mygrid;
x=mygrid.XC; y=mygrid.YC; u=fldUe; v=fldVn;
x(find(x>180))=x(find(x>180))-360;

%compute direction:
% eps=1e-3; %this value only works for a velocity field in m/s
eps=ceil(log10(sqrt(nanmean((u.^2+v.^2))))); eps=10^(-eps-3); %seems to work more generally
[xp,yp]=m_ll2xy(x+eps*u,y+eps*v.*cos(y*pi/180),'clip','point');
[x,y]=m_ll2xy(x,y,'clip','point');
complexVec=(xp-x)+i*(yp-y);
%scale amplitude
complexVec=complexVec./abs(complexVec).*abs(u+i*v);
%go back to reals:
fldUm=real(complexVec); fldUm(isnan(complexVec))=NaN;
fldVm=imag(complexVec); fldVm(isnan(complexVec))=NaN;

