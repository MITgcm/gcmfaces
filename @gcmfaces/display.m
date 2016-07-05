function display(a)
%overloaded gcmfaces display function :
%  displays the gcmfaces object content and attributes

stg = sprintf('      nFaces: %d\n',a.nFaces);
for iFace=1:a.nFaces; 
   eval(['tmp1=a.f' num2str(iFace) ';']); tmp1=size(tmp1);
   tmp2='['; 
   for ii=1:length(tmp1); tmp2=[tmp2 num2str(tmp1(ii)) 'x']; end;
   tmp2=[tmp2(1:end-1) ' ' class(tmp1) ']']; 
   stg=strvcat(stg,['      f' num2str(iFace) ': ' tmp2]);
end;
disp(stg)

