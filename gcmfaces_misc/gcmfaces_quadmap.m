function [ow]=gcmfaces_quadmap(px,py,ox,oy);
%[ow]=gcmfaces_quadmap(px,py,x,y);
%object:    compute bilinear interpolation coefficients for x(i,:),y(i,:)
%           in px(i,:),py(i,:) by remapping x(i,:),y(i,:) along with the
%           px(i,:),py(i,:) quadrilateral to the 0-1,0-1 square.
%inputs:    px,py are Mx4 matrices where each line specifies one quad
%(optional) ox,oy are MxP position matrices
%outputs:   pw are the MxPx4 bilinear interpolation weights

doDisplay=0;
if nargin==0;
    %the following test case is based upon https://www.particleincell.com/2012/quad-interpolation/
    %(see end of routine for alternatives)
    px = [-1, 8, 13, -4];
    py = [-1, 3, 11, 8];
    ox=0; oy=6;
    doDisplay=1;
end;

if nargin==2; ox=[]; oy=[]; end;

%solve linear problem for a,b vectors (knowing px,py)
%  logical (l,m) to physical (x,y) mapping is then
%  x=a(1)+a(2)*l+a(3)*m+a(2)*l*m;
%  y=b(1)+b(2)*l+b(3)*m+b(2)*l*m;
% A=[1 0 0 0;1 1 0 0;1 1 1 1;1 0 1 0]; AI = inv(A);
% AI=[1 0 0 0;-1 1 0 0;-1 0 0 1; 1 -1 1 -1];
% a = AI*px';
% b = AI*py';
tmp1=px(:,1);
tmp2=-px(:,1)+px(:,2);
tmp3=-px(:,1)+px(:,4);
tmp4=px(:,1)-px(:,2)+px(:,3)-px(:,4);
a=[tmp1 tmp2 tmp3 tmp4];
%
tmp1=py(:,1);
tmp2=-py(:,1)+py(:,2);
tmp3=-py(:,1)+py(:,4);
tmp4=py(:,1)-py(:,2)+py(:,3)-py(:,4);
b=[tmp1 tmp2 tmp3 tmp4];

%chose between the two mapping solutions dep. on sum of interior angles
[angsum]=gcmfaces_polygonangle(px,py);
sgn=NaN*px(:,1);
ii=find(abs(angsum-360)<1e-3); sgn(ii)=1;
ii=find(abs(angsum+360)<1e-3); sgn(ii)=-1;
ii=find(isnan(angsum)); 
if length(ii)>0;
    warning('edge point was found');
    keyboard;
end;

%solve non-linear problem for pl,pm (knowing px,py,a,b)
%  physical (x,y) to logical (l,m) mapping
%
% quadratic equation coeffs, aa*mm^2+bb*m+cc=0
if ~isempty(ox); 
    x=[px ox]; y=[py oy]; 
else; 
    x=px; y=py; 
end;
a=reshape(a,[size(a,1) 1 size(a,2)]); a=repmat(a,[1 size(x,2) 1]);
b=reshape(b,[size(b,1) 1 size(b,2)]); b=repmat(b,[1 size(x,2) 1]);
sgn=repmat(sgn,[1 size(x,2)]);
%
aa = a(:,:,4).*b(:,:,3) - a(:,:,3).*b(:,:,4);
bb = a(:,:,4).*b(:,:,1) -a(:,:,1).*b(:,:,4) + a(:,:,2).*b(:,:,3) ...
    - a(:,:,3).*b(:,:,2) + x.*b(:,:,4) - y.*a(:,:,4);
cc = a(:,:,2).*b(:,:,1) -a(:,:,1).*b(:,:,2) + x.*b(:,:,2) - y.*a(:,:,2);
%compute m = (-b+sqrt(b^2-4ac))/(2a)
det = sqrt(bb.*bb - 4.*aa.*cc);
pm = (-bb+sgn.*det)./(2.*aa);
%compute l by substitution in equation system
pl = (x-a(:,:,1)-a(:,:,3).*pm)./(a(:,:,2)+a(:,:,4).*pm);

ow=[];
if ~isempty(ox); 
    tmp1=(1-pl(:,5:end)).*(1-pm(:,5:end));
    tmp2=pl(:,5:end).*(1-pm(:,5:end));
    tmp3=pl(:,5:end).*pm(:,5:end);
    tmp4=(1-pl(:,5:end)).*pm(:,5:end);
    ow=cat(3,tmp1,tmp2,tmp3,tmp4);
end;

if doDisplay;
    cols='brgm';
    %
    figureL;
    %plot original quad and obs
    subplot(1,2,1);
    plot([px px(1)],[py py(1)],'k-','LineWidth',2); hold on;
    for pp=1:4;
        plot(px(pp),py(pp),[cols(pp) '.'],'MarkerSize',64);
    end;
    aa=axis; aa(1)=aa(1)-1; aa(2)=aa(2)+1; aa(3)=aa(3)-1; aa(4)=aa(4)+1; axis(aa);
    grid on; plot(ox,oy,'k.','MarkerSize',64);
    %
    subplot(1,2,2);
    plot([pl(1:4) pl(1)],[pm(1:4) pm(1)],'k-','LineWidth',2); hold on;
    for pp=1:4; plot(pl(pp),pm(pp),[cols(pp) '.'],'MarkerSize',64); end;
    aa=axis; aa(1)=aa(1)-1; aa(2)=aa(2)+1; aa(3)=aa(3)-1; aa(4)=aa(4)+1; axis(aa);
    grid on; plot(pl(5:end),pm(5:end),'k.','MarkerSize',64);
end;

%swap px and py:
% ppx=px; ppy=py;
% px=ppy; py=ppx;
%
%shift quad corners:
% nn=0;
% px=circshift(px,[0 nn]);
% py=circshift(py,[0 nn]);
%
%flip quad corners (see sum of interior angles):
% ppx=flipdim(px,2); ppy=flipdim(py,2);
% px=ppx; py=ppy;
%
%test cases for x,y locations:
% ox=0; oy=6;%inside point : sum(ang2)=+-360
% ox=(px(1)+px(2))/2; oy=(py(1)+py(2))/2;%edge limit case : sum(ang2)=+-180
% ox=(px(1)+px(4))/2; oy=(py(1)+py(4))/2;%edge limit case : sum(ang2)=-180
% ox=px(1); oy=py(1);%corner limit case : sum(ang2)=NaN
% ox=0; oy=12;%outside point : sum(ang2)=0
