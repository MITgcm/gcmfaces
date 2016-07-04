
gcmfaces_global;

warning('off','MATLAB:HandleGraphics:noJVM');

if myenv.verbose;
    fprintf('\n\n\n***********message from gcmfaces_init.m************\n ');
    fprintf(' starting basic test : example_IO ... \n');
end;
example_IO;

if ~myenv.lessplot;
    if myenv.verbose;
        fprintf('\n\n\n***********message from gcmfaces_init.m************\n ');
        fprintf(' starting plot test: example_display ... \n');
    end;
    example_display;
end;

if myenv.verbose;
    fprintf('\n\n\n***********message from gcmfaces_init.m************\n');
    fprintf(' --- initialization of gcmfaces completed correctly \n');
    fprintf(' --- you are all set and may now use the gcmfaces package. \n\n\n');
end;

