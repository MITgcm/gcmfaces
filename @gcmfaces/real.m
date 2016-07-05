function r = real(p)
%overloaded gcmfaces real function :
%  simply calls double real function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=real(p.f' iF ');']); 
end;


