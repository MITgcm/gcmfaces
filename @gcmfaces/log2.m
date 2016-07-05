function r = log2(p)
%overloaded gcmfaces log2 function :
%  simply calls double log2 function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=log2(p.f' iF ');']); 
end;


