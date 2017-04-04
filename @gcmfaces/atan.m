function r = atan(p)
%overloaded gcmfaces atan function :
%  simply calls double atan function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=atan(p.f' iF ');']); 
end;


