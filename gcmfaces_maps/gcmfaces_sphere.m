function []=gcmfaces_sphere(fld,cc,nn,vw,co);
%object:	display field and grid mesh on the sphere
%inputs:    fld is the field to be plotted
%           cc is the color range(s)
%           nn subsampling rate for grid lines ([] for no grid lines)
%           vw is either [],{az,elev},'N','S'
%           co color scheme option (1,2, or 3)
%
%Example: 
%  mask=mygrid.mskC(:,:,1);
%  bathy=mygrid.Depth;
%  figure; gcmfaces_sphere(mask.*bathy);

gcmfaces_global;

if isempty(who('cc')); cc=[]; end;
if isempty(who('nn')); nn=[]; end;
if isempty(who('vw')); vw=[]; end;
if isempty(who('co')); co=1; end;

if iscell(vw);
    az=vw{1}; elev=vw{2};
elseif isempty(vw);
    az=0; elev=20;
elseif strcmp(vw,'N');
    az=0; elev=90;
elseif strcmp(vw,'S');
    az=0; elev=-90;
end;

%overlay the mesh:
if ~isempty(nn);
    myfac=1.001;
    elev=myfac*elev;
end;

%color scheme:
if co==1;
    listCol='kkkkkk';
    bw=0;
    mm='jet';
elseif co==2;
    listCol='bbbbbb';
    bw=-2;
    mm='hot';
elseif co==3;
    listCol='gmbcrk'; if mygrid.nFaces==4; listCol='rgmc'; end;
    %%listCol='rkbcmg'; if mygrid.nFaces==4; listCol='mrkc'; end;
    bw=-2;
    mm='gray';
end;

%underlay plain sphere:
[xs,ys,zs]=sphere(100); aa=0.99;
aa=surf(aa*xs,aa*ys,aa*zs); hold on;
set(aa,'LineStyle','none','FaceColor',[1 1 1]*0.7);

%plot bathy:
test1=1; test2=0;
XC=exch_T_N(mygrid.XC); YC=exch_T_N(mygrid.YC);
FLD=exch_T_N(fld);
for ii=1:mygrid.nFaces;
    x=sin(pi/2-YC{ii}*pi/180).*cos(XC{ii}*pi/180);
    y=sin(pi/2-YC{ii}*pi/180).*sin(XC{ii}*pi/180);
    z=cos(pi/2-YC{ii}*pi/180);
    c=FLD{ii};
    %subsampling
    k0=1; i0=1:k0:size(x,1); j0=1:k0:size(x,2);
    surf(x(i0,j0),y(i0,j0),z(i0,j0),c(i0,j0),'LineStyle','none'); hold on;
    test1=nanmin([test1;c(:)]); test2=nanmax([test2;c(:)]);
end;%for ii=1:mygrid.nFaces;
axis equal; 
view(az,elev);
%
if length(cc)==0;
    cb=colorbar; colormap(mm);
elseif length(cc)==2;
    cb=colorbar; caxis(cc); colormap(mm);
elseif length(cc)>2;
    cb=gcmfaces_cmap_cbar(cc,{'myBW',bw},{'myCmap',mm});
end;
%
%set(cb,'Position',[0.78 0.2 0.02 0.6]);
%delete(cb);

if ~isempty(nn);
    if mygrid.nFaces~=4;
      XG=exch_Z(mygrid.XG); YG=exch_Z(mygrid.YG);
    else;
      %replace XG,YG with XC,YC since exch_Z_llpc is lacking
      XG=exch_T_N(mygrid.XC); YG=exch_T_N(mygrid.YC);
    end;
    %now do the plot:
    for ii=1:mygrid.nFaces;
        x=myfac*sin(pi/2-YG{ii}*pi/180).*cos(XG{ii}*pi/180);
        y=myfac*sin(pi/2-YG{ii}*pi/180).*sin(XG{ii}*pi/180);
        z=myfac*cos(pi/2-YG{ii}*pi/180);
        [n1,n2]=size(x); i1=[1:nn:n1]; i2=[1:nn:n2];
        mesh(x(i1,i2),y(i1,i2),z(i1,i2),0*x(i1,i2),'FaceColor','none','EdgeColor',listCol(ii)); hold on;
    end;
end;

%find tune plot:
axis equal; axis off;
%set(gca,'XTick',[],'YTick',[],'ZTick',[]);
%set(gca,'Color','none');
%set(gcf,'Renderer','zbuffer');
%box on;


