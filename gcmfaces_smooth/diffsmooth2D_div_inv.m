function [fldUdiv,fldVdiv,fldDivPot]=diffsmooth2D_div_inv(fldU,fldV);

%object: compute the divergent part of a tranport vector field
%	by solving a Laplace equation with Neumann B.C.
%
%input:	fldU,fldV	transport vectors (masked with NaNs)
%output:fldUdiv,fldVdiv	divergent part 
%	fldDivPot	Potential for the divergent flow (optional)	
%
%note 1: here we do everything in terms of transports, so we omit all
%	grid factors (i.e. with dx=dy=1), and the resulting potential 
%	has usits of transports.
%note 2: this routine was derived from diffsmooth2D_extrap_inv.m but
%	it differs in several aspects. It : 1) omits grid factors;
%	2) uses of a neumann, rather than dirichlet, boundary condition;
%	3) gets the mask directly from fld.

global mygrid;

warning('off','MATLAB:divideByZero');
warning('off','MATLAB:nearlySingularMatrix');

fld=calc_UV_conv(fldU,fldV,{});%no grid scaling factor in div. or transports
fld=fld.*mygrid.mskC(:,:,1);
%this can create isolated Canyons and a singular matrix: fld(fld==0)=NaN;
 
mskWet=fld; mskWet(~isnan(fld))=1;
mskDry=1*isnan(mskWet); mskDry(mskDry==0)=NaN;

%check for domain edge points where no exchange is possible:
tmp1=mskWet; tmp1(:)=1; tmp2=exch_T_N(tmp1);
for iF=1:mskWet.nFaces;
tmp3=mskWet{iF}; tmp4=tmp2{iF}; 
tmp4=tmp4(2:end-1,1:end-2)+tmp4(2:end-1,3:end)+tmp4(1:end-2,2:end-1)+tmp4(3:end,2:end-1);
if ~isempty(find(isnan(tmp4)&~isnan(tmp3))); fprintf('warning: mask was modified\n'); end;
tmp3(isnan(tmp4))=NaN; mskWet{iF}=tmp3; 
end;
%why does this matters... see set-ups with open boundary conditions...

%put 0 first guess if needed and switch land mask:
fld(find(isnan(fld)))=0; fld=fld.*mskWet;

%define mapping from global array to (no nan points) global vector
tmp1=convert2array(mskWet); 
kk=find(~isnan(tmp1)); nn=length(kk);
KK=tmp1; KK(:)=0; KK(kk)=kk; KKfaces=convert2array(KK); %global array indices
LL=tmp1; LL(:)=0; LL(kk)=[1:nn]; LLfaces=convert2array(LL); %global vector indices

%note:	diffsmooth2D_extrap_inv.m uses a Dirichlet boundary condition
%       so that it uses a nan/1 mask in KK/LL // here we use a 
%       Neumann boundary condition so we use a 0/1 mask (see below also)

%form matrix problem:
A=sparse([],[],[],nn,nn,nn*5);
for iF=1:fld.nFaces; for ii=1:3; for jj=1:3;

%1) seed points (FLDones) and neighborhood of influence (FLDkkFROM)
    FLDones=fld; FLDones(:)=0; 
    FLDones{iF}(ii:3:end,jj:3:end)=1; 
    FLDones(KKfaces==0)=0;

    FLDkkFROMtmp=fld; FLDkkFROMtmp(:)=0;
    FLDkkFROMtmp{iF}(ii:3:end,jj:3:end)=KKfaces{iF}(ii:3:end,jj:3:end);
    FLDkkFROMtmp(find(isnan(fld)))=0;

    FLDkkFROM=exch_T_N(FLDkkFROMtmp); FLDkkFROM(isnan(FLDkkFROM))=0; 
    for iF2=1:fld.nFaces; 
       tmp1=FLDkkFROM{iF2}; tmp2=zeros(size(tmp1)-2);
       for ii2=1:3; for jj2=1:3; tmp2=tmp2+tmp1(ii2:end-3+ii2,jj2:end-3+jj2); end; end;
       FLDkkFROM{iF2}=tmp2; 
    end;

%2) compute effect of each point on neighboring target point:
    [tmpU,tmpV]=calc_T_grad(FLDones,0);
%unlike calc_T_grad, we work in grid point index, so we need to omit grid factors
    tmpU=tmpU.*mygrid.DXC; tmpV=tmpV.*mygrid.DYC;
%and accordingly we use no grid scaling factor in div.
    [dFLDdt]=calc_UV_conv(tmpU,tmpV,{});

%note:	diffsmooth2D_extrap_inv.m uses a Dirichlet boundary condition
%	so that it needs to apply mskFreeze to dFLDdt // here we use a 
%	Neumann boundary condition so we do not mask dFLDdt (see above also)

%3) include seed contributions in matrix:
    FLDkkFROM=convert2array(FLDkkFROM);
%3.1) for wet points
    dFLDdtWet=convert2array(dFLDdt.*mskWet);
    tmp1=find(dFLDdtWet~=0&~isnan(dFLDdtWet)); 
    dFLDdtWet=dFLDdtWet(tmp1); FLDkkFROMtmp=FLDkkFROM(tmp1); FLDkkTOtmp=KK(tmp1);
    A=A+sparse(LL(FLDkkTOtmp),LL(FLDkkFROMtmp),dFLDdtWet,nn,nn);
%3.2) for dry points (-> this part reflects the neumann boundary condition)
    dFLDdtDry=convert2array(dFLDdt.*mskDry);
    tmp1=find(dFLDdtDry~=0&~isnan(dFLDdtDry));
    dFLDdtDry=dFLDdtDry(tmp1); FLDkkFROMtmp=FLDkkFROM(tmp1);
    A=A+sparse(LL(FLDkkFROMtmp),LL(FLDkkFROMtmp),dFLDdtDry,nn,nn);

end; end; end;

%to check results: 
%figure; spy(A);

%4) solve for potential:
yy=convert2array(fld); yy=yy(find(KK~=0));
%Solving A xx = yy
%Original, but less robust, way to solve A xx = yy
% is use xx=A\yy;.
% When matrix A is close to singular, xx may become 
% all zeros. Different versions of MATLAB
% may have different behaviors. For instance,  
% when using calc_barostream.m (which calls
% diffsmooth2D_div_inv.m) to calculate barotropic stream function,   
% gcmfaces using matlab/2017b was able to find a solution that 
% appears fine, while matlab/2021a gives a solution 
% of all zeros. 
%xx=A\yy;
%Use the more robust way to solve xx
%in a least squares sense. This method
%can also handle sparse matrix and is
%more efficient than pinv (which cannot handle sparse matrix).
%Warning is turned on to monitor if the matrix is close to singular.
xx=lsqminnorm(A,yy,'warn');

yyFROMxx=A*xx; 

%5) prepare output:
fldDivPot=0*convert2array(fld); fldDivPot(find(KK~=0))=xx;
fldDivPot=convert2array(fldDivPot);
[fldUdiv,fldVdiv]=calc_T_grad(fldDivPot,0);
%unlike calc_T_grad, we work in grid point index, so we need to omit grid factors
fldUdiv=fldUdiv.*mygrid.DXC; fldVdiv=fldVdiv.*mygrid.DYC;

%to check the results:
%fld1=0*convert2array(fld); fld1(find(KK~=0))=xx;
%fld2=0*convert2array(fld); fld2(find(KK~=0))=yyFROMxx;
%fld3=convert2array(calc_UV_conv(fldU,fldV,{}));%no grid scaling factor in div. or transports

warning('on','MATLAB:divideByZero');
warning('on','MATLAB:nearlySingularMatrix');

