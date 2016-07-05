function [FLD]=diffsmooth2D_extrap_fwd(fld,mskOut,eps);
%object: 	extrapolate an incomplete field to create a full field, by 
%			time-stepping a diffusion equation to near-equilibrium.
%inputs: 	fld	incomplete field of interest (masked with NaN)
%		mskOut	land mask (1s and NaNs) for the full field (output)
%		eps	convergence criterium
%output:	FLD	full field

global mygrid;

dxC=mygrid.DXC; dyC=mygrid.DYC; 
rA=mygrid.RAC;

dxCsm=dxC; dyCsm=dyC;

%mask of points which values will evolve 
doStep=1*(isnan(fld));

%put first guess:
x=convert2array(mygrid.XC);
y=convert2array(mygrid.YC);
z=convert2array(fld);
m=convert2array(mskOut);
tmp1=find(~isnan(z));
tmp2=find(~isnan(m));
zz=z;
zz(tmp2) = griddata(x(tmp1),y(tmp1),z(tmp1),x(tmp2),y(tmp2),'nearest');
fld=convert2array(zz);

%put 0 first guess if needed and switch land mask:
fld(find(isnan(fld)))=0; fld=fld.*mskOut;

%scale the diffusive operator:
tmp0=dxCsm./dxC; tmp0(isnan(mskOut))=NaN; tmp00=nanmax(tmp0);
tmp0=dyCsm./dyC; tmp0(isnan(mskOut))=NaN; tmp00=max([tmp00 nanmax(tmp0)]);
smooth2D_nbt=tmp00;
smooth2D_nbt=ceil(1.1*2*smooth2D_nbt^2);

smooth2D_dt=1;
smooth2D_T=smooth2D_nbt*smooth2D_dt;
smooth2D_Kux=dxCsm.*dxCsm/smooth2D_T/2;
smooth2D_Kvy=dyCsm.*dyCsm/smooth2D_T/2;

%setup problem:
myOp.dt=1;
myOp.eps=eps;
myOp.Kux=smooth2D_Kux;
myOp.Kvy=smooth2D_Kvy;
myOp.doStep=doStep;

%time step problem:
FLD=gcmfaces_timestep(myOp,fld);


