function [Unodiv,Vnodiv,Wnodiv]=calc_uvw_nodiv(UVELMASS,VVELMASS);
%[Unodiv,Vnodiv,Wnodiv]=calc_uvw_nodiv(UVELMASS,VVELMASS);
% calculates non-divergent U,V,W fields from UVELMASS,VVELMASS

gcmfaces_global;

drf=mk3D(mygrid.DRF,UVELMASS); 
dxg=mk3D(mygrid.DXG,drf); dyg=mk3D(mygrid.DYG,drf); 
facW=drf.*dyg; facS=drf.*dxg;

%integrate vertically and apply surface mask:
tmpU=nansum(facW.*UVELMASS,3).*mygrid.mskW(:,:,1); 
tmpV=nansum(facS.*VVELMASS,3).*mygrid.mskS(:,:,1);

%compute divergent transport:
[tmpUdiv,tmpVdiv,tmpDivPot]=diffsmooth2D_div_inv(tmpU,tmpV);

%compute divergent velocity:
tmpU=sum(facW.*mygrid.hFacW,3).*mygrid.mskW(:,:,1); 
tmpV=sum(facS.*mygrid.hFacS,3).*mygrid.mskS(:,:,1);
tmpUdiv=tmpUdiv./tmpU; tmpVdiv=tmpVdiv./tmpV;

Udiv=mk3D(tmpUdiv,drf).*mygrid.hFacW;
Vdiv=mk3D(tmpVdiv,drf).*mygrid.hFacS;
Unodiv=UVELMASS-Udiv; 
Vnodiv=VVELMASS-Vdiv;

%verify result:
%tmpU=nansum(facW.*Unodiv,3).*mygrid.mskW(:,:,1); 
%tmpV=nansum(facS.*Vnodiv,3).*mygrid.mskS(:,:,1);
%[tmpUdiv2,tmpVdiv2,tmpDivPot2]=diffsmooth2D_div_inv(tmpU,tmpV);

%compute vertical component:
tmp=calc_UV_conv(facW.*Unodiv,facS.*Vnodiv);
Wnodiv=cumsum(tmp,3,'reverse')./mk3D(mygrid.RAC,drf);


