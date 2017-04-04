function r = cosd(p)
%overloaded gcmfaces cosd function :
%  simply calls double cosd function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=cosd(p.f' iF ');']); 
end;


