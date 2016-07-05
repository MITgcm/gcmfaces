function [field_out]=sym_g(field_in,sym_in,op_in);
%apply symmetry in the complex plane to field_in(z)
%      where field_in and z are in the complex arrays.
%then, depending on op_in, we apply a compensating operation
%
%format of field_in:
%               z(1,:) is z=-1+?i, z(end,:) is z=1+?i
%               z(:,1) is z=?-i, z(:,end) is z=?+i
%
%sym_in:        1,2,3,4 are reflexions about x=0,y=0,x=y,x=-y
%               4+nRot is rotation by nRot*pi/2
%               0 just returns the input field as output
%op_in:         1 apply the opposite complex operation

field_out=field_in;
if isempty(whos('op_in')); op_in=0; end; 

if sym_in==0;
    %do nothing
elseif sym_in==1;
    field_out=flipdim(field_in,1);
    if op_in==1; field_out=-real(field_out)+i*imag(field_out); end;
elseif sym_in==2;
    field_out=flipdim(field_in,2);
    if op_in==1; field_out=real(field_out)-i*imag(field_out); end;
elseif sym_in==3;
    field_out=permute(field_in,[2,1,3,4]);
    if op_in==1; field_out=imag(field_out)+i*real(field_out); end;
elseif sym_in==4;
    field_out=flipdim(permute(flipdim(field_in,1),[2,1,3,4]),1);
    if op_in==1; field_out=-imag(field_out)-i*real(field_out); end;
elseif sym_in>=5&sym_in<=7;
    for icur=1:sym_in-4;
        field_out=flipdim(permute(field_out,[2,1,3,4]),1);
        if op_in==1; field_out=i*field_out; end;
    end
else;
    fprintf('error in sym_g2\n'); return;
end;

%for test case:
%--------------
%xx=[1:10]'*ones(1,10); yy=xx';
%zz=zeros(10,10); zz(1:2,1:3)=1; zz(8,9)=2; zz(2,6:8)=-1; zz(7,3)=-2;
%sym_g(zz,1); %etc
%with the following uncommented:
%-------------------------------
%figure;
%subplot(2,2,1); imagesc(field_in);
%subplot(2,2,4); imagesc(field_out);
%xlabel('y'); xlabel('x');


