function r = cat(nDim,p,q)
%overloaded gcmfaces cat function :
%  simply calls double cat function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=cat(nDim,p.f' iF ',q.f' iF ');']); 
end;


