
.. _install:

Getting Started
===============

.. _soft:

Install Software
----------------

Download the latest software version from `github <https://github.com/gaelforget/>`__ by typing

::

    git clone https://github.com/gaelforget/gcmfaces
    git clone https://github.com/gaelforget/MITprof

at the command line or using the github web browser interface. This method allows users to update the software later on and to manage their own, if any, code modifications. Archived frozen versions of the software, which can be cited in publications using permanent digital object identifiers, are also available via `zenodo <https://zenodo.org/badge/latestdoi/62541910>`__. Additionally, `gcmfaces` relies on the `m_map` toolbox for geographic projections (:numref:`plot_one_field_M_MAP`), which can be downloaded from `this webpage <https://www.eoas.ubc.ca/~rich/map.html>`__ (e.g., `m_map1.4.tar.gz <http://www.eos.ubc.ca/~rich/m_map1.4.tar.gz>`__).

Octave users will want to replace ``git clone ...faces`` with ``git clone -b octave ...faces`` in the above recipe. They will also need to install and load the Octave `statistics <https://octave.sourceforge.io/statistics/index.html>`__, `io <https://octave.sourceforge.io/io/index.html>`__, and `netcdf <https://octave.sourceforge.io/netcdf/index.html>`__ packages.

.. note::

       `MITprof` is not generally needed by `gcmfaces`, but is used in :numref:`demo` and :numref:`standard`.

.. _data:

Obtain Input Data
-----------------

The `gcmfaces` toolbox allows users to seamlessly deal with various gridding
approaches (e.g., all grids distributed via `this MIT server
<https://engaging-web.mit.edu/~gforget/harbor/version_4/grids>`__)
using compact and generic codes as explained in this user guide. Once a
grid has been loaded to memory (see below and :numref:`Cgrid`), `gcmfaces` can be used
to analyze ocean model solutions and state estimates on that grid
(:numref:`demo` and :numref:`standard`).


To get started in :numref:`getting_started` and :numref:`features`, it
suffices to download ``nctiles_grid/`` (145M) either from `this MIT
server <https://engaging-web.mit.edu/~gforget/harbor/version_4/release2/nctiles_grid/>`__
or from `this permanent archive <http://dx.doi.org/10.7910/DVN/H8W5VW>`__.
:numref:`demo` and :numref:`standard` use ``nctiles_climatology/`` (10G)
to illustrate higher-level functionalities. One download method, from the
command line, is shown in :ref:`downloads`. Commands reported afterwards assume
that downloaded contents are organized as shown in :ref:`gcmfaces_demo_dirtree`.

The other input data sets shown in :ref:`gcmfaces_demo_dirtree` (inside of ``release2/``)
are not be needed unless user wants to reproduce the full set of plots in :cite:`dspace-eccov4r2`.
The contents of ``profiles/`` (7G) and ``nctiles_remotesensing/`` (27G) allow for model-data
comparisons, while ``nctiles_monthly/`` (170G) contains monthly
time series of ocean variables over 1992-2011. These can be used
to reproduce the plots in :cite:`dspace-eccov4r2` via a few
function calls as explained at the end of :numref:`standard`.

.. _downloads:

.. rubric:: Demo Directory Downloads

::

    setenv FTPv4r2 'https://engaging-web.mit.edu/~gforget/harbor/version_4/release2'
    wget --recursive {$FTPv4r2}/nctiles_grid
    wget --recursive {$FTPv4r2}/nctiles_climatology
    #wget --recursive {$FTPv4r2}/nctiles_monthly
    #wget --recursive {$FTPv4r2}/nctiles_remotesensing
    #wget --recursive {$FTPv4r2}/profiles

.. _gcmfaces_demo_dirtree:

.. rubric:: Demo Directories Organization

.. include:: gcmfaces_demo_dirtree.rst

.. _getting_started:

Activate gcmfaces
-----------------

Once ``gcmfaces/`` and ``nctiles_grid/`` have been placed in a
common directory as shown in :ref:`gcmfaces_demo_dirtree`,
open Matlab or Octave from within that directory and type:

::

    %add gcmfaces and MITprof directories to Matlab path:
    p = genpath('gcmfaces/'); addpath(p);
    %p = genpath('MITprof/'); addpath(p);

    %load all grid variables from nctiles_grid/ into mygrid:
    grid_load;

    %make mygrid accessible in current workspace:
    gcmfaces_global;

    %display list of grid variables:
    disp(mygrid);

    %display one gcmfaces variable:
    disp(mygrid.XC);
