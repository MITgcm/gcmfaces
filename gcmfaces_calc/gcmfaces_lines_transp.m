function [line_out]=gcmfaces_lines_transp(varargin);
%object:    compute geat circle transport lines, defined 
%           by pair of coordinates, for use in calc_transports
%inputs:    lonPairs (e.g. [-68 -63] by default) is the pair of longitudes
%           latPairs (e.g. [-54 -66] by default) is the pair of latgitudes
%           names (e.g. {'Drake Passage'} by default) is the transport line name
%output:    (optional) line_out is a strcuture with the following fields 
%           lonPair, latPair, name, mskCedge, mskWedge, mskSedge
%           If no output is specified then line_out is copied to 
%           mygrid (global variable) as 'mygrid.LINES_MASKS'

global mygrid;

if nargin>0;
    lonPairs=varargin{1};
    latPairs=varargin{2};
    names=varargin{3};
else;
    lonPairs=[-68 -63];
    latPairs=[-54 -66];
    names={'Drake Passage'};
end;

for iy=1:length(names);
    
    lonPair=lonPairs(iy,:);
    latPair=latPairs(iy,:);
    name=names{iy};
    
    %get carthesian coordinates:
    %... of grid
    lon=mygrid.XC; lat=mygrid.YC;
    x=cos(lat*pi/180).*cos(lon*pi/180);
    y=cos(lat*pi/180).*sin(lon*pi/180);
    z=sin(lat*pi/180);
    %... and of end points
    x0=cos(latPair*pi/180).*cos(lonPair*pi/180);
    y0=cos(latPair*pi/180).*sin(lonPair*pi/180);
    z0=sin(latPair*pi/180);
    
    %get the rotation matrix:
    %1) rotate around x axis to put first point at z=0
    theta=atan2(-z0(1),y0(1));
    R1=[[1;0;0] [0;cos(theta);sin(theta)] [0;-sin(theta);cos(theta)]];
    tmp0=[x0;y0;z0]; tmp1=R1*tmp0; x1=tmp1(1,:); y1=tmp1(2,:); z1=tmp1(3,:);
    x0=x1; y0=y1; z0=z1;
    %2) rotate around z axis to put first point at y=0
    theta=atan2(x0(1),y0(1));
    R2=[[cos(theta);sin(theta);0] [-sin(theta);cos(theta);0] [0;0;1]];
    tmp0=[x0;y0;z0]; tmp1=R2*tmp0; x1=tmp1(1,:); y1=tmp1(2,:); z1=tmp1(3,:);
    x0=x1; y0=y1; z0=z1;
    %3) rotate around y axis to put second point at z=0
    theta=atan2(-z0(2),-x0(2));
    R3=[[cos(theta);0;-sin(theta)] [0;1;0] [sin(theta);0;cos(theta)]];
    tmp0=[x0;y0;z0]; tmp1=R3*tmp0; x1=tmp1(1,:); y1=tmp1(2,:); z1=tmp1(3,:);
    x0=x1; y0=y1; z0=z1;
    
    %apply rotation to grid:
    tmpx=convert2array(x); tmpy=convert2array(y); tmpz=convert2array(z);
    tmp1=find(~isnan(tmpx));
    tmpx2=tmpx(tmp1); tmpy2=tmpy(tmp1); tmpz2=tmpz(tmp1);
    tmp2=[tmpx2';tmpy2';tmpz2'];
    tmp3=R3*R2*R1*tmp2;
    tmpx2=tmp3(1,:); tmpy2=tmp3(2,:); tmpz2=tmp3(3,:);
    tmpx(tmp1)=tmpx2; tmpy(tmp1)=tmpy2; tmpz(tmp1)=tmpz2;
    x=convert2array(tmpx); y=convert2array(tmpy); z=convert2array(tmpz);

    %compute the great circle mask:
    mskCint=1*(z>0);
    [mskCedge,mskWedge,mskSedge]=gcmfaces_edge_mask(mskCint);
        
    %select the shorther segment:
    for kk=1:3;
        %select field to treat:
        switch kk;
            case 1; mm=mskCedge;
            case 2; mm=mskWedge;
            case 3; mm=mskSedge;
        end;
        %split in two segments:
        theta=[];
        theta(1)=atan2(y0(1),x0(1));
        theta(2)=atan2(y0(2),x0(2));
        
        tmpx=convert2array(x); tmpy=convert2array(y); tmpz=convert2array(z);
        tmptheta=atan2(tmpy,tmpx);
        tmpm=convert2array(mm);
        if theta(2)<0;
            tmp00=find(tmptheta<=theta(2)); tmptheta(tmp00)=tmptheta(tmp00)+2*pi;
            theta(2)=theta(2)+2*pi;
        end;
        %select the shorther segment:
        if theta(2)-theta(1)<=pi;
            tmpm(find(tmptheta>theta(2)|tmptheta<theta(1)))=NaN;
        else;
            tmpm(find(tmptheta<=theta(2)&tmptheta>=theta(1)))=NaN;
        end;
        mm=convert2array(tmpm);
        %store result:
        switch kk;
            case 1; mskCedge=mm;
            case 2; mskWedge=mm;
            case 3; mskSedge=mm;
        end;
    end;
    
    %store so-defined line:
    line_cur=struct('lonPair',lonPair,'latPair',latPair,'name',name,...
        'mskCedge',mskCedge,'mskWedge',mskWedge,'mskSedge',mskSedge);
        
    %add to lines:
    if iy==1;
        LINES_MASKS=line_cur;
    else;
        LINES_MASKS(iy)=line_cur;
    end;
    
end;

if nargout==0; %add to mygrid
  mygrid.LINES_MASKS=LINES_MASKS;
else;          %output to line_out 
  line_out=line_cur;
end;


