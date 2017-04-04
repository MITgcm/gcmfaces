function r = tand(p)
%overloaded gcmfaces tand function :
%  simply calls double tand function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=tand(p.f' iF ');']); 
end;


