function r = squeeze(p)
%overloaded gcmfaces squeeze function :
%  simply calls double squeeze function for each face data

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=squeeze(p.f' iF ');']); 
end;


