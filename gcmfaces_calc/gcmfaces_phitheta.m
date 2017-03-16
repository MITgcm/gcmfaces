function [PHI,phi,varargout]=gcmfaces_phitheta(T,dT,Theta,varargin);
% GCMFACES_PHITHETA parameterized probability distribution diagnostic
%
%     [PHI,phi]=gcmfaces_phitheta(T,dT,Theta) computes the 
%     probabilities that theta<=Theta (PHI) and theta=Theta (phi) 
%     assuming that the theta probably density is homogeneous around T 
%     (i.e., equal to 1/2/dT in the [T-dT T+dT] range).
%
%     [PHI,phi,dPHIdt]=gcmfaces_phitheta(T,dT,Theta,H) additionally
%     computes the -phi*H rate of change in PHI associated with the 
%     action of H.
%
%     The T input can be from the double or gcmfaces class whereas dT and
%     Theta must be of the double class. While dT must be a scalar value, 
%     T and/or Theta can have one or several non-singleton dimensions. 
%     In these cases T and Theta dimensions get coumpounded except 
%     for singleton dimensions when T or Theta is a column vector.
%
% examples:
% 
%     T=[3:0.01:10]; dT=0.5; Theta=6; 
%     [PHI,phi]=gcmfaces_phitheta(T,dT,Theta);
%
%     T=[3:0.01:10]'; dT=0.5; Theta=[-3:0.1:30]'; 
%     [PHI,phi]=gcmfaces_phitheta(T,dT,Theta);
%
%     dir0='release2_climatology/nctiles_climatology/'; rhocp=1029.*3994;
%     SST=read_nctiles([dir0 'THETA/THETA'],'THETA',[],1);
%     oceQnet=read_nctiles([dir0 'oceQnet/oceQnet'],'oceQnet');
%     [PHI,phi,dPHIdt]=gcmfaces_phitheta(SST,0.5,6,1/rhocp*oceQnet);

if ~isempty(which('gcmfaces_global')); gcmfaces_global; end;
if isempty(which('gcmfaces_global'))&isa(T,'gcmfaces');
    error('gcmfaces is missing from Matlab path');
end;

if nargin<3; error('incorrect input parameter specification'); end;

%identify input dimensions
if isa(T,'gcmfaces'); ndimT=size(T{1}); else; ndimT=size(T); end;
if ndimT(end)==1; ndimT=length(ndimT)-1; else; ndimT=length(ndimT); end;
ndimTheta=length(size(Theta));

%replicate T if needed to coumpound dimensions
tmp1=[ones(1,ndimT) size(Theta)];
T=repmat(T,tmp1);
for ii=1:nargin-3;
    varargout{ii}=repmat(varargin{ii},tmp1);
end;

%replicate Theta if needed to coumpound dimensions
tmp1=[[1:ndimT]+ndimTheta [1:ndimTheta]];
Theta=permute(Theta,tmp1);
if isa(T,'gcmfaces');
    tmp1=size(T{1});
    tmp1=[mygrid.ioSize tmp1(3:ndimT) ones(1,ndimTheta)];
    Theta=convert2gcmfaces(repmat(Theta,tmp1));
else;
    tmp1=size(T);
    tmp1=[tmp1([1:ndimT]) ones(1,ndimTheta)];
    Theta=repmat(Theta,tmp1);
end;

%compte PHI and phi
PHI=(Theta-T+dT)/(2*dT);
phi=0*T+1/(2*dT);

PHI(PHI<0)=0; PHI(PHI>1)=1;
phi(PHI==0)=0; phi(PHI==1)=0;

%compute transformation rates
for ii=1:nargin-3;
    varargout{ii}=-varargout{ii}.*phi;
end;


