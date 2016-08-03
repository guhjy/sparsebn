sparsebn
========

[![Travis-CI Build Status](https://travis-ci.org/itsrainingdata/sparsebn.svg?branch=master)](https://travis-ci.org/itsrainingdata/sparsebn)

Methods for learning sparse Bayesian networks and other graphical models from high-dimensional data via sparse regularization. Designed to handle:

-   Experimental data with interventions
-   Mixed observational / experimental data
-   High-dimensional data with *p &gt;&gt; n*
-   Datasets with thousands of variables (tested up to *p*=8000)
-   Continuous and discrete data

The workhorse behind `sparsebn` is the [`sparsebnUtils`](http://www.github.com/itsrainingdata/sparsebnUtils/) package, which provides various S3 classes and methods for representing and manipulating graphs. The basic algorithms are implemented in [`ccdrAlgorithm`](http://www.github.com/itsrainingdata/ccdrAlgorithm/) and [`discretecdAlgorithm`](http://www.github.com/gujyjean/discretecdAlgorithm/).

Overview
--------

The main methods for learning graphical models are:

-   `estimate.dag` for directed acyclic graphs (Bayesian networks).
-   `estimate.precision` for undirected graphs (Markov random fields).
-   `estimate.covariance` for covariance matrices.

Installation
------------

You can install:

-   the latest CRAN version with

    ``` r
    install.packages("sparsebn")
    ```

-   the latest development version from GitHub with

    ``` r
    devtools::install_github(c("itsrainingdata/sparsebn/", "itsrainingdata/sparsebnUtils/dev", "itsrainingdata/ccdrAlgorithm/dev", "gujyjean/discretecdAlgorithm"))
    ```
