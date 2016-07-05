function [mskCedge,mskWedge,mskSedge]=gcmfaces_edge_mask(mskCint);
%object:    computes the edge mask corresponding with
%           an ocean basin interior mask
%inputs:    mskCint is the 0/1 mask defining an ocean basin interior
%outputs:   mskCedge is the tracer edge mask (1 point outside interior)
%           mskWedge/mskSedge is the U/V velocity mask (1 for entering 
%               flow, -1 for exiting flow, and 0 otherwise)

gcmfaces_global;

%treat the case of blank tiles:
mskCint(mygrid.RAC==0)=NaN;

%add one point at edges:
mskCplus=exch_T_N(mskCint);

%edge tracer mask:
mskCedge=mskCint;
for iF=1:mskCint.nFaces;
    tmp1=mskCplus{iF};
    tmp2=tmp1(2:end-1,1:end-2)+tmp1(2:end-1,3:end)...
        +tmp1(1:end-2,2:end-1)+tmp1(3:end,2:end-1);
    mskCedge{iF}=1*(tmp2>0&tmp1(2:end-1,2:end-1)==0);
end;

%edge velocity mask:
mskWedge=mskCint; mskSedge=mskCint;
for iF=1:mskCplus.nFaces;
   mskWedge{iF}=mskCplus{iF}(2:end-1,2:end-1) - mskCplus{iF}(1:end-2,2:end-1);
   mskSedge{iF}=mskCplus{iF}(2:end-1,2:end-1) - mskCplus{iF}(2:end-1,1:end-2);
end;

%treat the case of blank tiles:
mskCedge(isnan(mskCedge))=0;
mskWedge(isnan(mskWedge))=0;
mskSedge(isnan(mskSedge))=0;
