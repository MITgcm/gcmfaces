
.. _install:

Install And Get Started
=======================

.. _soft:

Software Installation
---------------------

Download the latest software version from `github <https://github.com/gaelforget/>`__ by typing 

::

    git clone https://github.com/gaelforget/gcmfaces
    git clone https://github.com/gaelforget/MITprof

at the command line or using the github web browser interface. This method allows users to update the software later on and to manage their own, if any, code modifications. Archived frozen versions of the software, which can be cited in publications using permanent digital object identifiers, are also available via `zenodo <https://zenodo.org/badge/latestdoi/62541910>`__.

.. _data:

Demo Data Downloads
-------------------

Getting started in :numref:`getting_started` and :numref:`features`) only requires 
a download of ``nctiles_grid/`` (145M) either from `this ftp
server <ftp://mit.ecco-group.org/ecco_for_las/version_4/release2/nctiles_grid/>`__
or from `this permanent archive <http://dx.doi.org/10.7910/DVN/H8W5VW>`__. To illustrate
higher-level functions in :numref:`demo` and :numref:`standard` we use additional data
taken from :cite:`dspace-eccov4r2` as shown in :ref:`gcmfaces_demo_dirtree` 
that can be downloaded at the command line as shown in :ref:`downloads`.

Downloading ``nctiles_climatology/`` (10G), ``nctiles_grid/`` (145M), and
the `gcmfaces`, `MITprof`, and `m_map` toolboxes is sufficient for the basic 
purposes of :numref:`demo` and :numref:`standard`. The files
in ``profiles/`` (7G) and ``nctiles_remotesensing/`` (27G) allow for
model-data comparisons. The ``nctiles_monthly/`` directory (170G) contains 
the 1992-2011 monthly time series of ocean variables that can be used 
to reproduce the plots in :cite:`dspace-eccov4r2` via a few 
function calls (:numref:`standard`).

.. _downloads:

.. rubric:: Demo Directory Downloads

::

    setenv FTPv4r2 'ftp://mit.ecco-group.org/ecco_for_las/version_4/release2/'
    #export FTPv4r2='ftp://mit.ecco-group.org/ecco_for_las/version_4/release2/'
    wget --recursive {$FTPv4r2}/nctiles_grid
    wget --recursive {$FTPv4r2}/nctiles_climatology
    wget --recursive {$FTPv4r2}/nctiles_monthly
    wget --recursive {$FTPv4r2}/nctiles_remotesensing
    wget --recursive {$FTPv4r2}/profiles

.. _gcmfaces_demo_dirtree:

.. rubric:: Demo Directories Organization

.. include:: gcmfaces_demo_dirtree.rst

.. _getting_started:

Get Started
-----------

Once ``gcmfaces/``, ``MITprof/``, and ``nctiles_grid/`` have been placed in a
common directory as shown in :ref:`gcmfaces_demo_dirtree`,
open Matlab from that directory and type:

::

    %add gcmfaces and MITprof directories to Matlab path:
    p = genpath('gcmfaces/'); addpath(p);
    p = genpath('MITprof/'); addpath(p);

    %load all grid variables from nctiles_grid/ into mygrid:
    grid_load; 

    %make mygrid accessible in current workspace:
    gcmfaces_global;

    %display list of grid variables:
    disp(mygrid);

    %display one gcmfaces variable:
    disp(mygrid.XC);

