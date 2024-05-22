.. gcmfaces documentation master file, created by
   sphinx-quickstart on Tue Jan 16 02:04:13 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to gcmfaces' documentation!
===================================

.. A Generic Treatment Of Gridded Earth Variables In Matlab And Octave.

Here, you will learn about the `gcmfaces` toolbox that provides a generic
treatment of gridded Earth variables in Matlab and Octave.

The `gcmfaces` toolbox handles gridded Earth variables as sets of connected
arrays. This object-oriented approach allows users to
write generic, compact analysis codes that readily become applicable
to a wide variety of grids (e.g., those in :numref:`sphere_all`).
`gcmfaces` notably allows for analysis of MITgcm output on any of its
`familiar grids <https://engaging-web.mit.edu/~gforget/harbor/version_4/grids/>`__.
It was originally developed as part the `ECCO version 4` framework along with
the companion `MITprof` toolbox that handles unevenly
distributed in-situ ocean observations :cite:`for-eta:15`.

This user manual provides an installation guide for `gcmfaces` and `MITprof`
(:numref:`install`), a documentation of the basic `gcmfaces` features
(:numref:`features`), and an overview of higher-level `gcmfaces` functionalities
for mapping, transport, etc. operations (:numref:`demo` and :numref:`standard`).

.. toctree::
   :maxdepth: 3
   :caption: Contents
   :numbered: 4

   prep_install.rst
   prep_basic.rst
   prep_demo.rst
   prep_diags.rst
   biblirefs.rst

Sample grids
============

.. figure:: figs/sphere_all.pdf
   :width: 95%
   :align: center
   :alt: TBD
   :name: sphere_all

   Four approaches to gridding the Earth which are all commonly used in numerical models. Top left: lat-lon grid; mapping the Earth to a single rectangular array (`face`). Top right: cube-sphere grid; mapping the earth to the six faces of a cube. Bottom right: lat-lon-cap, `LLC`, grid (five faces). Bottom left: quadripolar grid (four faces). In this depiction, faces are color-coded, only grid line subsets are shown, and gaps are introduced between faces to highlight the defining characteristics of each grid.

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
