function [varargout]=layers_remap(P,pType,tracer,trGrid,nDblRes);
%object : remap variables (e.g. transports) from depth to tracer classes.
%input :  P is the variable of interest
%         pType is 'extensive' or 'intensive'
%         tracer is the tracer field (3D; at cell center in depth space).
%         trGrid is the tracer space grid (1D; centers of tracer bins).
%         nDblRes is the number of resolution doublings (in depth, not tracer space)
%output : P is the remapped variable
%notes : this was not fully tested for intensive quantities

gcmfaces_global;

doUV=iscell(P);%should depend on argument list
if isempty(whos('nDblRes')); nDblRes=0; end;%default is no grid refinement
tracer=tracer.*mygrid.mskC;%needed for trW/S, and regrid_dblres/intensive

if ~doUV;
    listVar={'P'}; listTr={'tracer'}; listPos={'C'};
else;
    listVar={'U','V'}; listTr={'trW','trS'};  listPos={'W','S'};
    %
    U=P{1}; V=P{2};
    %
    FLD=exch_T_N(tracer);
    trW=NaN*tracer; trS=NaN*tracer;
    for iF=1:FLD.nFaces;
        tmpA=FLD{iF}(2:end-1,2:end-1,:);
        tmpB=FLD{iF}(1:end-2,2:end-1,:);
        trW{iF}=(tmpA+tmpB)/2;
        tmpA=FLD{iF}(2:end-1,2:end-1,:);
        tmpB=FLD{iF}(2:end-1,1:end-2,:);
        trS{iF}=(tmpA+tmpB)/2;
    end;
end;

for ii=1:length(listVar);
    %rename
    eval(['P=' listVar{ii} '; tracer=' listTr{ii} ';']);
    
    %set to extensive
    if strcmp(pType,'intensive');
        if listPos{ii}=='C'; dxy=mk3D(mygrid.RAC,P).*mygrid.hFacC;
        elseif listPos{ii}=='W'; dxy=mk3D(mygrid.DYG,P);
        elseif listPos{ii}=='S'; dxy=mk3D(mygrid.DXG,P);
        else; error('unknown position');
            %document the different weights about C vs U/V
        end;
        S=dxy.*mk3D(mygrid.DRF,P);
        P=P.*S;
    end;

    %apply mask
    eval(['P=P.*mygrid.msk' listPos{ii} ';']);
    
    %grid refinement (if nDblRes>0)
    tracer=regrid_dblres(tracer,'intensive',nDblRes);
    P=regrid_dblres(P,'extensive',nDblRes);
    
    %the very remaping
    P=regrid_sum(P,tracer,trGrid);
    
    %reset to intensive
    if strcmp(pType,'intensive'); 
        eval(['S=S.*mygrid.msk' listPos{ii} ';']);
        S=regrid_dblres(S,'extensive',nDblRes);
        S=regrid_sum(S,tracer,trGrid);
        P=P./S; 
    end;
    
    %rename
    eval([listVar{ii} '=P;']);
end;

%output result
if ~doUV; varargout={P}; else; varargout={U,V}; end;

    

