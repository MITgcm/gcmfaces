function r = cos(p)
%overloaded gcmfaces cos function :
%  simply calls double cos function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=cos(p.f' iF ');']); 
end;


