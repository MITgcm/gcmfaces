function r = sin(p)
%overloaded gcmfaces sin function :
%  simply calls double sin function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=sin(p.f' iF ');']); 
end;


