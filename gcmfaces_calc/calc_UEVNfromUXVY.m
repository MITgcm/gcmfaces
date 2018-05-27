function [fldUe,fldVn]=calc_UEVNfromUXVY(fldU,fldV);
%object:    compute Eastward/Northward vectors form X/Y vectors
%inputs:    fldU/fldV are the X/Y vector fields at velocity points
%outputs:   fldUe/fldVn are the Eastward/Northward vectors at tracer points

gcmfaces_global;

%fldU(mygrid.hFacW==0)=NaN; fldV(mygrid.hFacS==0)=NaN;
nr=size(fldU.f1,3); fldU(mygrid.hFacW(:,:,1:nr)==0)=NaN; fldV(mygrid.hFacS(:,:,1:nr)==0)=NaN;

[fldUe,fldVn]=calc_UV_zonmer(fldU,fldV);