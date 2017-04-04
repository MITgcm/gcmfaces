function [Ug,Vg]=calc_UV_geos(P);
%[Ug, Vg]=calc_UV_geos(P); 
% computes geostrophic velocities from horizontal pressure anomaly field P
%
% example:
%
%  %read actual model velocity field
%  U=mean(read_nctiles('release2_climatology/nctiles_climatology/UVELMASS/UVELMASS'),4);
%  V=mean(read_nctiles('release2_climatology/nctiles_climatology/VVELMASS/VVELMASS'),4);
%  %read hydrostatic pressure gradient computed along R* surface:
%  P=mean(read_nctiles('release2_climatology/nctiles_climatology/PHIHYD/PHIHYD'),4);
%  %correct, approximately, for slope of R* surface:
%    ETAN=mean(read_nctiles('release2_climatology/nctiles_climatology/ETAN/ETAN'),3);
%    tmp1=mygrid.mskC.*mk3D(ETAN,P);%free surface height
%    tmp2=mk3D(mygrid.DRF,P).*(1-mygrid.hFacC);%grounded thickness
%    tmp3=mygrid.mskC.*mk3D(-mygrid.RC,P)-1/2*tmp2;%depth of R* center points
%    tmp4=mygrid.mskC.*mk3D(mygrid.Depth,P);%bottom depth
%    tmp5=1-(tmp1+tmp3)./(tmp1+tmp4);
%  P=P+tmp5.*mk3D(9.81*ETAN,P);
%
%  %compute geostrophy
%  [Ug,Vg]=calc_UV_geos(P);
%
%  %display results
%  kk=10; cc=[-1 1]*0.1;
%  kk=30; cc=[-1 1]*0.05;
%  kk=40; cc=[-1 1]*0.02;
%  figure; orient tall; m=mygrid.mskC(:,:,kk);
%  [tmpu,tmpv]=calc_UEVNfromUXVY(U(:,:,kk),V(:,:,kk));
%  [tmpug,tmpvg]=calc_UEVNfromUXVY(Ug(:,:,kk),Vg(:,:,kk));
%  subplot(3,1,1); qwckplot(m.*tmpu); caxis(cc); colorbar; title('zonal flow');
%  subplot(3,1,2); qwckplot(m.*tmpug); caxis(cc); colorbar; title('geostrophic flow');
%  subplot(3,1,3); qwckplot(m.*tmpu-tmpug); caxis(cc); colorbar; title('difference');
%

% development notes:
%  is P assumed NaN-masked?
%  add to example_transports? Along with Ekman transport?
%  hard-coded rhoconst, g, gamma should be stated in help section
%  k loop should be possible to remove; once done also for calc_T_grad
%  should allow for application to ETAN x appropriate constant as 2D input

gcmfaces_global;

% mask=squeeze(mygrid.hFacC(:,:,1));
% dzf=mygrid.DRF;
nz=length(mygrid.RC); 

%constants
rhoconst=1029; 
g=9.81; 
omega=7.27e-5;

[dxC, dyC]=exch_UV_N(mygrid.DXC, mygrid.DYC);

%f=2*omega*sind(mygrid.YC);
%fmat=exch_T_N(f);
f=2*omega*sind(mygrid.YG);
fmat=exch_Z(f);

%replace NaN/1 mask with 0/1 mask:
P(isnan(P))=0;
mskW=mygrid.mskW; mskW(isnan(mskW))=0;
mskS=mygrid.mskS; mskS(isnan(mskS))=0;
%%weight average by portion that is filled
%mskW=mygrid.hFacW;
%mskS=mygrid.hFacS;

%mask out near-equator values:
tmp1=1+0*mygrid.YC;
tmp1(abs(mygrid.YC)<10)=NaN;
P=P.*repmat(tmp1,[1 1 nz]);

%main computational loop:
Ug=zeros(P,nz);
Vg=zeros(P,nz);

for iz=1:nz
    [dpdx,dpdy]=calc_T_grad(squeeze(P(:,:,iz)), 0);
    dpdx=dpdx.*mskW(:,:,iz);
    dpdy=dpdy.*mskS(:,:,iz);
    [dpdx, dpdy]=exch_UV_N(dpdx, dpdy); %add extra points
     
    [mask_u, mask_v]=exch_UV_N(squeeze(mskW(:,:,iz)), squeeze(mskS(:,:,iz)));
    mask_u=abs(mask_u); mask_v=abs(mask_v); %mask is always positive
    
    %average up to 4 points to get value at correct location
    ucur=Ug(:,:,iz);
    vcur=Vg(:,:,iz);

    for iF=1:mygrid.nFaces
        [nx,ny]=size(mygrid.XC{iF});
        [nx2,ny2]=size(mask_u{iF});
        
        cur_dpdx=dpdx{iF}(2:nx2,1:ny2-1);
        cur_dpdy=dpdy{iF}(1:nx2-1,2:ny2);
        cur_masku=mask_u{iF}(2:nx2,1:ny2-1);
        cur_maskv=mask_v{iF}(1:nx2-1,2:ny2);
        
        f=(fmat{iF}(1:nx,1:ny)+fmat{iF}(2:nx+1,1:ny))/2;
        npts=cur_masku(1:nx,1:ny)+cur_masku(2:nx+1,1:ny)+cur_masku(1:nx,2:ny+1)+cur_masku(2:nx+1,2:ny+1);
        ii=find(npts==0);
        npts(ii)=NaN;
        vcur{iF}=(cur_dpdx(1:nx,1:ny)+cur_dpdx(2:nx+1,1:ny)+cur_dpdx(1:nx,2:ny+1)+cur_dpdx(2:nx+1,2:ny+1))./(f.*npts);
        vcur{iF}(ii)=NaN;
        
        f=(fmat{iF}(1:nx,1:ny)+fmat{iF}(1:nx,2:ny+1))/2;
        npts=cur_maskv(1:nx,1:ny)+cur_maskv(2:nx+1,1:ny)+cur_maskv(1:nx,2:ny+1)+cur_maskv(2:nx+1,2:ny+1);
        ii=find(npts==0);
        npts(ii)=NaN;
        ucur{iF}=-1*(cur_dpdy(1:nx,1:ny)+cur_dpdy(2:nx+1,1:ny)+cur_dpdy(1:nx,2:ny+1)+cur_dpdy(2:nx+1,2:ny+1))./(f.*npts);
        ucur{iF}(ii)=NaN;                
    end;
    
    Ug(:,:,iz)=ucur;
    Vg(:,:,iz)=vcur;
end
    
mskW=mygrid.mskW; ii=find(isnan(mskW)); mskW(ii)=0;
mskS=mygrid.mskS; ii=find(isnan(mskS)); mskS(ii)=0;    
Vg=Vg.*mskS;
Ug=Ug.*mskW;



