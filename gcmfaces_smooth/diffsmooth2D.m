function [FLD]=diffsmooth2D(fld,dxCsm,dyCsm);
%object: diffusive smoother (after Weaver and Courtier 2001)
%
%input:	fld	          field to be smoothed (masked with NaN)
%       dxCsm,dyCsm	  scale in first/second grid direction
%output:FLD	          smoothed field
%
%asumption: dxCsm/dyCsm are given at U/V points (as DXC/DYC are)

global mygrid;

%scale the diffusive operator:
dxC=mygrid.DXC; dyC=mygrid.DYC;

tmp0=dxCsm./dxC; tmp0(isnan(fld))=NaN; tmp00=nanmax(tmp0);
tmp0=dyCsm./dyC; tmp0(isnan(fld))=NaN; tmp00=max([tmp00 nanmax(tmp0)]);
nbt=tmp00;
nbt=ceil(1.1*2*nbt^2);

dt=1;
T=nbt*dt;

%diffusion operator:
Kux=dxCsm.*dxCsm/T/2;
Kvy=dyCsm.*dyCsm/T/2;

%setup problem:
myOp.dt=1;
myOp.nbt=nbt;
myOp.Kux=Kux;
myOp.Kvy=Kvy;

%time step problem:
FLD=gcmfaces_timestep(myOp,fld);
