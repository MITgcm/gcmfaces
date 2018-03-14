
.. _standard:

Standard Analysis
=================

The `gcmfaces standard analysis` consists of an extensive set of
physical diagnostics that are routinely computed to monitor and compare
MITgcm simulations and ECCO state estimates :cite:`for-eta:15`, :cite:`dspace-eccov4r2`. 
The computational loop is operated by ``diags_driver.m`` which stores intermediate 
results in a dedicated directory (``mat/`` in :ref:`gcmfaces_demo_dirtree`). Afterwards,
the display phase is operated via ``diags_display.m`` or
``diags_driver_tex.m`` as explained below.

In order to proceed, user should have completed the installation procedure in
:numref:`install` and organized directories as shown in :ref:`gcmfaces_demo_dirtree`. 
They can then, for example, generate and display variance maps from the ECCO v4 
monthly mean climatology (12 monthly fields) by opening Matlab
and executing ``diags_set_B.m`` as follows:

::

    %add paths:
    p = genpath('gcmfaces/'); addpath(p);
    p = genpath('MITprof/'); addpath(p);
    p = genpath('m_map/'); addpath(p);

    %set parameters:
    dirModel='release2_climatology/'; 
    dirMat=[dirModel 'mat/'];
    setDiags='B';

    %compute diagnostics:
    diags_driver(dirModel,dirMat,'climatology',setDiags);

    %display results:
    diags_display(dirMat,setDiags);

which should take :math:`\approx5` minutes. Each generated plot has a caption
that indicates the quantity being displayed. Results of ``diags_driver.m``
can, alternatively, be displayed via ``diags_driver_tex.m`` to save plots
and create a compilable tex file. This process should take :math:`\approx`\ 10
minutes:

::

    dirTex=[dirModel 'tex/']; nameTex='standardAnalysis';
    diags_driver_tex(dirMat,{},dirTex,nameTex);

Other diagnostic sets can be computed and displayed accordingly by
modifying the `setDiags` specification: oceanic transports (`A`), mean
and variance maps (`B`), sections and time series (`C`), and mixed layer
depths (`MLD`). Each set of diagnostics (computation and display) is
encoded in one routine named as `diags_set_XX.m` where `XX` stands for
e.g., `A`, `B`, `C`, or `MLD`. 

These routines can be found in the ``gcmfaces_diags/`` subdirectory.
Computing all four diagnostic sets from ECCO v4 r2 climatology takes
:math:`\approx`\ 1/2 hour. Computing them from the 1992-2011 monthly
time series (``nctiles_monthly/`` in :ref:`gcmfaces_demo_dirtree`) 
by typing

::

    dirModel='release2/'; dirMat=[dirModel 'mat/'];
    diags_driver(dirModel,dirMat,[1992:2011]);

takes :math:`\approx20` times longer and typically runs overnight.
However, to speed up the process, computation can be distributed over
multiple processors by splitting [1992:2011] into subsets.
