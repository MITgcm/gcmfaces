function r = atand(p)
%overloaded gcmfaces atand function :
%  simply calls double atand function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=atand(p.f' iF ');']); 
end;


