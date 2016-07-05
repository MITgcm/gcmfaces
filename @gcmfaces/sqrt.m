function r = sqrt(p)
%overloaded gcmfaces sqrt function :
%  simply calls double sqrt function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=sqrt(p.f' iF ');']); 
end;


