function r = isnan(p)
%overloaded gcmfaces isnan function :
%  simply calls double isnan function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=isnan(p.f' iF ');']); 
end;


