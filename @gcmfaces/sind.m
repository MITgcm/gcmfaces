function r = sind(p)
%overloaded gcmfaces sind function :
%  simply calls double sind function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=sind(p.f' iF ');']); 
end;


