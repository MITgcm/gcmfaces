function [FLD]=gcmfaces_timestep(myOp,fld,fldRelax);
%object:    time step a 2D tracer diffusion/relaxation (could later be
%               extended with 3D case, advection and surface forcing)
%inputs:    myOp specifies the equation with the following fields
%               dt   time step
%               nbt  number of time steps
%               eps  termination criterium
%               Kux, Kvy diffusion coefficients (along grid axes; m2/s)
%               tau  relaxation time scale
%               Kuy, Kvx diffusion coefficients (only for rotated diff)
%               doStep   is a field of 0 (tracer stays unchanged) 
%                        and 1 (tracer evolves).
%           fld is the initial tracer field
%           fldRelax is the field to relax to (if tau<Inf)
%output:    FLD is the final tracer field
%
%note : case of 3D tracer is not coded yet
%note : advection (m/s) and forcing (tracer/area/s) are not coded yet


gcmfaces_global;

if isempty(who('fldRelax'));   fldRelax=[]; end;
if isempty(who('fldForcing')); fldForcing=[]; end;

%rotated diffusion:
if isfield(myOp,'Kuy')&&isfield(myOp,'Kvx');
    if ~isempty(myOp.Kuy)&&~isempty(myOp.Kvx);
        doExtraDiag=1;
        if myenv.verbose;
            gcmfaces_msg(['* extra-diagonal diffusion included.']);
        end;
    else;
        doExtraDiag=0;
    end;
else;
    doExtraDiag=0;
end;

%relaxation term:
if isfield(myOp,'tau');
    doRelax=1;
    if isempty(fldRelax);
        error('relaxation field must be specified');
    end;
    if ~isa(myOp.tau,'double')&&~isa(myOp.tau,'gcmfaces');
        error('mispecified relaxation time scale (must be doule or gcmfaces)');
    end;
    
    if myenv.verbose;
        gcmfaces_msg(['* relaxation term included.']);
    end;
    test1=1*(myOp.tau<myOp.dt);
    if isa(myOp.tau,'gcmfaces'); test1=convert2vector(test1); end;
    test1=~isempty(find(test1==1));
    if test1;
        error('tau cannot exceed 1');
    end;
else;
    doRelax=0;
end;

%mask of frozen/evolving points:
if isfield(myOp,'doStep');
    doStep=myOp.doStep;
    test1=sum(doStep~=1&doStep~=0);
    if test1;
        error('myOp.doStep must be a field of 0/1');
    end;
else;
    doStep=mygrid.XC; doStep(:)=1;
end;

%forcing term:
if ~isempty(fldForcing);
    doForcing=1;
    if myenv.verbose;
        gcmfaces_msg(['* forcing term included.']);
    end;
else;
    doForcing=0;
end;

%
if isfield(myOp,'eps');
    nbt=Inf;
    eps=myOp.eps;
    if myenv.verbose;
        gcmfaces_msg(['* specified termination : ' num2str(eps) ' .']);
    end;
else;
    nbt=myOp.nbt;
    eps=0;
    if myenv.verbose;
        gcmfaces_msg(['* specified number of time steps : ' num2str(nbt) ' .']);
    end;
end;

%initialization
FLD=fld; it=0; doStop=0; nrm=[]; nrmRef=Inf;

%time-stepping loop:
while ~doStop;
    
    it=it+1;
    
    [dTdxAtU,dTdyAtV]=calc_T_grad(FLD,0);
    tmpU=dTdxAtU.*myOp.Kux;
    tmpV=dTdyAtV.*myOp.Kvy;
    
    if doExtraDiag;
        dTdyAtU=dTdxAtU; dTdxAtV=dTdyAtV;
        [dTdxAtU,dTdyAtV]=exch_UV_N(dTdxAtU,dTdyAtV);
        for iF=1:FLD.nFaces;
            msk=dTdxAtU{iF}(2:end-1,2:end-1); msk(~isnan(msk))=1;
            tmp1=dTdyAtV{iF}; tmp1(isnan(tmp1))=0;
            dTdyAtU{iF}=0.25*msk.*(tmp1(1:end-2,2:end-1)+tmp1(1:end-2,3:end)+...
                tmp1(2:end-1,2:end-1)+tmp1(2:end-1,3:end));
            
            msk=dTdyAtV{iF}(2:end-1,2:end-1); msk(~isnan(msk))=1;
            tmp1=dTdxAtU{iF}; tmp1(isnan(tmp1))=0;
            dTdxAtV{iF}=0.25*msk.*(tmp1(2:end-1,1:end-2)+tmp1(3:end,1:end-2)+...
                tmp1(2:end-1,2:end-1)+tmp1(3:end,2:end-1));
        end;
        dTdxAtU=cut_T_N(dTdxAtU);
        dTdyAtV=cut_T_N(dTdyAtV);
        
        tmpU=tmpU+dTdyAtU.*myOp.Kuy;
        tmpV=tmpV+dTdxAtV.*myOp.Kvx;
    end;
    
    [fldDIV]=calc_UV_conv(tmpU,tmpV,{'dh'});
    dFLDdt=-myOp.dt*fldDIV./mygrid.RAC;
    
    if doRelax;
        dFLDdt=dFLDdt+myOp.dt*(fldRelax-FLD)./myOp.tau;
    end;
    
    %mask of frozen/evolving points:
    dFLDdt=dFLDdt.*doStep;
    
    %now step forward
    FLD=FLD+dFLDdt;
    
    %test for termination criteria
    nrm=[nrm;sqrt(nanmean(dFLDdt.^2))];
    if it==1; nrmRef=nrm(it); end;
    doStop=((nrm(it)<nrmRef*eps)|(it==nbt));
    
    %monitor convergence
    if mod(it,50)==0||it==1||doStop;
        tmp1=sprintf('it=%04i  100*nrm/nrmRef=%4.4g.',it,100*nrm(it)/nrmRef);
        if myenv.verbose;
            gcmfaces_msg(['* convergence monitor : ' tmp1]);
        end;        
    end;
    
    if 0;%monitor convergence
        if mod(it,1000)==0||doStop;
            figure; plot(log10(nrm)); ylabel('log10(increment)');
            eval(['FLD_' num2str(it) '=FLD;']);
        end;
    end;
    
    if 0;%test of positivity
        test1=convert2vector(FLD<0); test1=~isempty(find(test1(:)==1));
        if test1;
            fprintf(['it=' num2str(it) ' min(FLD)=' num2str(min(FLD)) '\n']);
        end;
    end;
    
end;

