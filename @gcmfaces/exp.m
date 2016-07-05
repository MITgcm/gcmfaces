function r = exp(p)
%overloaded gcmfaces exp function :
%  simply calls double exp function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=exp(p.f' iF ');']); 
end;


