function []=example_smooth(fld);
% EXAMPLE_SMOOTH(fld) applies smoothing filters to fld
% 
% Example:
%   fld=example_bin_average;
%   example_smooth(fld);

gcmfaces_global;

if myenv.verbose>0;
    gcmfaces_msg('===============================================');
    gcmfaces_msg('*** entering example_smooth : apply smoother to gridded data');
end;

%%%%%%%% apply land mask %%%%%%%%

if myenv.verbose>0;
    gcmfaces_msg('* apply land mask (1/NaN) to gridded before smoothing');
end;
fld=fld.*mygrid.mskC(:,:,1);

%%%%%%%% isotropic diffusion %%%%%%%%

%choose smoothing scale: here 3 X grid spacing
if myenv.verbose>0;
    gcmfaces_msg('** set the smoothing scale to 3 grid points');
end;
distXC=3*mygrid.DXC; distYC=3*mygrid.DYC;

%do the smoothing:
if myenv.verbose>0;
    gcmfaces_msg(['* call diffsmoth2D : apply smoothing operator ' ...
        'that consists in time stepping a diffusion equation ' ...
        'with accordingly chosen diffusivity and duration. In particular ' ...
        'diffsmoth2D illustrates gradient computations (using calc_T_grad) ' ...
        'and convergence computations (using calc_UV_conv).']);
end;
fld_smooth=diffsmooth2D(fld,distXC,distYC);

%display results:
if myenv.verbose>0;
    gcmfaces_msg('* display results on sphere');
end;

figureL; set(gca,'FontSize',16);
gcmfaces_sphere(fld_smooth); caxis([-1 1]*0.4); colorbar;
title('smoothed bin averaged data')

%%%%%%%% rotated diffusion %%%%%%%%

%choose smoothing scale: here 3 X grid spacing
if myenv.verbose>0;
    gcmfaces_msg('** set anisotropic and rotated smoothing');
end;
distLarge=3*sqrt(mygrid.RAC); distSmall=1*sqrt(mygrid.RAC);
fldRef=mygrid.YC;

%do the smoothing:
if myenv.verbose>0;
    gcmfaces_msg(['* call diffsmoth2Drotated : apply anisotropic smoothing operator ' ...
        'that acts preferentially along contours of a reference field (here latitude).']);
end;
fld_smooth2=diffsmooth2Drotated(fld,distLarge,distSmall,mygrid.YC);

%display results:
if myenv.verbose>0;
    gcmfaces_msg('* display results on sphere');
end;

figureL; set(gca,'FontSize',16);
gcmfaces_sphere(fld_smooth2); caxis([-1 1]*0.4); colorbar;
title('anisotropic smoother result')


if myenv.verbose>0;
    gcmfaces_msg('*** leaving example_smooth');
    gcmfaces_msg('===============================================');
end;

