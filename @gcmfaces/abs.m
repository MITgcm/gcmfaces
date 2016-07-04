function r = abs(p)
%overloaded gcmfaces abs function : 
%  simply calls double abs function for each face data

r=p;
for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=abs(p.f' iF ');']); 
end;


