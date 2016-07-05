
%%%%%%%%%%%%%%%%%%%%%%%%
%format conversions
if myenv.verbose>0;
    gcmfaces_msg('* call convert2array : convert from gcmfaces to array format');
end;
obsArray=convert2array(obsMap);%put in gcmfaces format
if myenv.verbose>0;
    gcmfaces_msg('* call convert2array : convert back to gcmfaces');
end;
obsMap2=convert2array(obsArray);%put in gcmfaces format
if myenv.verbose>0;
    gcmfaces_msg('* call convert2gcmfaces : convert from gcmfaces to file format');
end;
obsOut=convert2gcmfaces(obsMap);        %put in gcm input format
if myenv.verbose>0;
    gcmfaces_msg('* summarizing data formats:');
    aa=whos('obs*');
    aaa=aa(4); bb=['[' num2str(aaa.size(1)) 'x' num2str(aaa.size(2)) ']'];
    bb=fprintf('   %8s %8s %12s    : data points (vector)\n',aaa.name,aaa.class,bb);
    aaa=aa(2); bb=['[' num2str(aaa.size(1)) 'x' num2str(aaa.size(2)) ']'];
    bb=fprintf('   %8s %8s %12s    : gridded data (gcmfaces)\n',aaa.name,aaa.class,bb);
    aaa=aa(1); bb=['[' num2str(aaa.size(1)) 'x' num2str(aaa.size(2)) ']'];
    bb=fprintf('   %8s %8s %12s    : array format\n',aaa.name,aaa.class,bb);
    aaa=aa(3); bb=['[' num2str(aaa.size(1)) 'x' num2str(aaa.size(2)) ']'];
    bb=fprintf('   %8s %8s %12s    : output format\n',aaa.name,aaa.class,bb);
end;

