function [trP]=regrid_sum(P,tracer,trGrid);
%object : add 3rd dimension elements of extensive variable P,
%         according to values of a tracer field collocated with P,
%         to the tracer grid defined by trGrid (1D vector)
%input :  P is the extensive variable of interest
%         tracer is the associated tracer field
%         trGrid is the vector of tracer values at
%            bins center of the tracer grid bins.
%output : trP is the counterpart to P on the tracer grid

trP=NaN*repmat(P(:,:,1),[1 1 length(trGrid)-1]);
trBounds=[-Inf (trGrid(1:end-1)+trGrid(2:end))/2 Inf];
for kk=1:length(trGrid);
    tmp1=P.*(tracer>=trBounds(kk)).*(tracer<trBounds(kk+1));
    trP(:,:,kk)=nansum(tmp1,3);
end;
