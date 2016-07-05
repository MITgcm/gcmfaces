function r = angle(p)
%overloaded gcmfaces angle function :
%  simply calls double angle function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=angle(p.f' iF ');']); 
end;


