function [msk]=v4_basin_one(numBasin);
%object : compute mask for a basin defined by a vector of points
%
%notes : - algorithm is based on great circles
%        - individual basin needs to be convex
%
%example of usage :
%fld=read_bin('v4_basin.bin',0,1);
%fld(fld>17)=18;%reset indices to proper basin
%fld(fld>17&mygrid.XC>-40)=19;%reset indices to proper basin                                                                    
%msk1=v4_basin_one(1); msk2=v4_basin_one(2);
%fld(fld<10&(msk1==1|msk2==1))=20;%add new basin index

gcmfaces_global;

if numBasin==1;
lonList=[10 19 60 60 ];
latList=[60 80 81 60]; 
elseif numBasin==2;
lonList=[60 100 110 60];
latList=[81 80  60  60];        
else;
error('unknown basin');
end;

lonList=[lonList lonList(1)];
latList=[latList latList(1)];

msk=mygrid.mskC(:,:,1);
for iy=1:length(lonList)-1;

    lonPair=lonList(iy:iy+1);
    latPair=latList(iy:iy+1);

    lon=mygrid.XC; lat=mygrid.YC;
    x=cos(lat*pi/180).*cos(lon*pi/180);
    y=cos(lat*pi/180).*sin(lon*pi/180);
    z=sin(lat*pi/180);

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

    %increment msk:
    msk(mskCint>0)=0;
end;

