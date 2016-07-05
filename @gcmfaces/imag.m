function r = imag(p)
%overloaded gcmfaces imag function :
%  simply calls double imag function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=imag(p.f' iF ');']); 
end;


