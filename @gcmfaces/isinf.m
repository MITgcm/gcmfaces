function r = isinf(p)
%overloaded gcmfaces isinf function :
%  simply calls double isinf function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=isinf(p.f' iF ');']); 
end;


