function [FLD]=diffsmooth2Drotated(fld,dxLarge,dxSmall,fldRef);
%
%object: slanted diffusive smoother (after Weaver and Courtier 2001)
%
%input:	fld	             field to be smoothed (masked with NaN)
%       dxLarge,dySmall	 smoothing scale in direction of 
%                        weak,strong fldRef gradient
%       fldRef           tracer field which gradient defines 
%                        directions of strong,weak smoothing
%output:FLD	             smoothed field
%
%asumption: dxLarge/dxSmall are given at tracer points (not U/V points)

global mygrid;

dxC=mygrid.DXC; dyC=mygrid.DYC; 
dxG=mygrid.DXG; dyG=mygrid.DYG; 
rA=mygrid.RAC;

%scale the diffusive operator:
tmp0=dxLarge./dxC; tmp0(isnan(fld))=NaN; tmp00=nanmax(tmp0);
tmp0=dxLarge./dyC; tmp0(isnan(fld))=NaN; tmp00=max([tmp00 nanmax(tmp0)]);
nbt=tmp00;
nbt=ceil(1.1*2*nbt^2);

dt=1;
T=nbt*dt;

%diffusion operator:
kLarge=dxLarge.*dxLarge/T/2;
kSmall=dxSmall.*dxSmall/T/2;
[Kux,Kuy,Kvx,Kvy]=diffrotated(kLarge,kSmall,fldRef);

%setup problem:
myOp.dt=1;
myOp.nbt=nbt;
myOp.Kux=Kux;
myOp.Kuy=Kuy;
myOp.Kvx=Kvx;
myOp.Kvy=Kvy;

%time step problem:
FLD=gcmfaces_timestep(myOp,fld);

