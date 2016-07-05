function a = mk3D(b,c)
%function a = mk3D(b,c)
%  => makes a 3D field of the same format as c, based on b, which may be
%  either  	[A] a 2D field consistent with c(:,:,1)
%  or		[B] a 1D vector concistent
%  
%  in case [A], if b has more that 2D, then the first 2D field is used
%  in case [B], if the length of b is n3=size(c.f1,3), then we map b(k) to 
%  a(:,:,k). Otherwise we map b(1) to a(:,:,k) and issue a warning.

a=c;
n3=size(a.f1,3);

if isa(b,'gcmfaces');
   %go from 2D field to 3D field
      for iFace=1:a.nFaces;
         iF=num2str(iFace);
         eval(['tmp1=b.f' iF ';']); [n1,n2]=size(tmp1); tmp1=tmp1(:); 
         tmp1=tmp1*ones(1,size(a.f1,3)); tmp1=reshape(tmp1,[n1 n2 n3]);
         eval(['a.f' iF '=tmp1;']);
      end;
elseif isa(b,'double');
      if length(b)~=1&length(b)~=n3; fprintf('     mk3D warning: b(1) is used \n'); end;
      if length(b)~=n3; b=b(1)*ones(1,n3); end;
      if size(b,1)~=1; b=b'; end;
      for iFace=1:a.nFaces;   
         iF=num2str(iFace);
         eval(['tmp1=c.f' iF ';']); tmp2=size(tmp1); n1=tmp2(1); n2=tmp2(2);
         tmp1=reshape(ones(n1*n2,1)*b,[n1 n2 n3]);;
         eval(['a.f' iF '=tmp1;']);
      end;
else
   error('indexing not supported by gcmfaces objects')
end


