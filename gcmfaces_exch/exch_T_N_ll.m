function [FLD]=exch_T_N_ll(fld,varargin);

gcmfaces_global;

if nargin==2; N=varargin{1}; else; N=1; end;

if ~isfield(mygrid,'domainPeriodicity'); 
fprintf('\nexch_T_N_ll.m init: different 1 face configurations may \n');
fprintf('  differ with respect to domain periodicity. By default gcmfaces \n');  
fprintf('  assumes 0 periodicity, except that if the first dimension has n*90 \n');
fprintf('  points it is assumed to be periodic. If this is inadequate, \n');
fprintf('  you can set domainPeriodicity yourself as explained below.\n\n');
%domainPeriodicity=[0 0];%no periodidicity
%domainPeriodicity=[1 0];%1st dimension only is periodic
%domainPeriodicity=[0 1];%2nd dimension only is periodic
%domainPeriodicity=[1 0];%both dimensions are periodic
if mod(size(fld{1},1),90)==0; 
  mygrid.domainPeriodicity=[1 0];
else; 
  mygrid.domainPeriodicity=[0 0];
end;
end;

FLD=fld;
s=size(FLD.f1); s(1:2)=s(1:2)+2*N; FLD.f1=NaN*zeros(s);

n3=max(size(fld.f1,3),1); n4=max(size(fld.f1,4),1);
for k3=1:n3; for k4=1:n4;

f1=fld.f1(:,:,k3,k4);
nan1=NaN*ones(N,size(fld.f1,2));
nan2=NaN*ones(size(FLD.f1,1),N); 
%face 1:
if mygrid.domainPeriodicity(1); F1=[f1(end-N+1:end,:);f1;f1(1:N,:)]; 
else; F1=[nan1;f1;nan1]; end;
if mygrid.domainPeriodicity(2); F1=[F1(:,end-N+1:end) F1 F1(:,1:N)];
else; F1=[nan2 F1 nan2]; end;

%store:
FLD.f1(:,:,k3,k4)=F1;

end; end;

