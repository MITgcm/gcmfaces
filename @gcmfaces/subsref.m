function b = subsref(a,index)
%overloaded gcmfaces subsref function : subscripted reference according to
%  beta{n}     will return the n^{th} face data (array).
%  beta(:,:,n) will return the n^{th} vertical level (gcmfaces).
%  beta.nFaces will return the nFaces attribute (double).

switch index(1).type
case '{}'
   nFaces=get(a,'nFaces');
   iFace=index(1).subs{:};
   if iFace<=nFaces&iFace>0;
      eval(['b=a.f' num2str(iFace) ';']);
   else
      error('Index out of range')
   end

   if length(index)>1; b=subsref(b,index(2:end)); end;
case '.'
   b = get(a,index(1).subs);

   if length(index)>1; b=subsref(b,index(2:end)); end;
case '()'
   if length(index)>1; error('indexing not supported by gcmfaces objects'); end;

   b=a; 
   for iFace=1:a.nFaces; iF=num2str(iFace); 
      if isa(index.subs{1},'gcmfaces');
         eval(['b.f' iF '=a.f' iF '(index.subs{1}.f' iF ');']);
      else;
         eval(['b.f' iF '=subsref(a.f' iF ',index);']);
      end;
   end;
otherwise
   error('indexing not supported by gcmfaces objects')
end


