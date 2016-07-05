function r = log10(p)
%overloaded gcmfaces log10 function :
%  simply calls double log10 function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=log10(p.f' iF ');']); 
end;


