function [angsum]=gcmfaces_polygonangle(px,py,x,y);
%[angsum]=gcmfaces_polygonangle(px,py,x,y);
%object:    compute sum of interior angles for polygons (when input
%           is px,py) or points vs polygons (when input is px,py,x,y)
%inputs:    px,py are MxN matrices where each line specifies one polygon
%(optional) x,y are position vectors
%outputs:   ang are the corresponding sums of interior angles

M=size(px,1); N=size(px,2);
doPointsInPolygon=0; P=1;
if nargin>2;
    doPointsInPolygon=1;
    sizxy=size(x);
    x=reshape(x,[1 prod(sizxy)]);
    y=reshape(y,[1 prod(sizxy)]);
    P=length(x);
end;

angsum=zeros(M,P);
for ii=0:N-1;
    ppx=circshift(px,[0 -ii]);
    ppy=circshift(py,[0 -ii]);
    
    if ~doPointsInPolygon;
        %compute sum of corner angles
    v1x=ppx(:,2)-ppx(:,1); 
    v1y=ppy(:,2)-ppy(:,1);
    v2x=ppx(:,4)-ppx(:,1); 
    v2y=ppy(:,4)-ppy(:,1);
    else;
        %compute sum of sector angles        
        v1x=ppx(:,1)*ones(1,P)-ones(M,1)*x; 
        v1y=ppy(:,1)*ones(1,P)-ones(M,1)*y;
        v2x=ppx(:,2)*ones(1,P)-ones(M,1)*x; 
        v2y=ppy(:,2)*ones(1,P)-ones(M,1)*y;
    end;
    g_acos=acos( ( v1x.*v2x+v1y.*v2y )./sqrt( v1x.*v1x+v1y.*v1y )./sqrt( v2x.*v2x+v2y.*v2y ) );
    g_sin= ( v1x.*v2y-v1y.*v2x )./sqrt( v1x.*v1x+v1y.*v1y )./sqrt( v2x.*v2x+v2y.*v2y ) ;
    angsum=angsum+radtodeg(g_acos.*sign(g_sin));    
end;

