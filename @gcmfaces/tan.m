function r = tan(p)
%overloaded gcmfaces tan function :
%  simply calls double tan function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=tan(p.f' iF ');']); 
end;


