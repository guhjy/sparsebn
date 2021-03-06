#
#  sparsebn-main.R
#  sparsebn
#
#  Created by Bryon Aragam (local) on 5/11/16.
#  Copyright (c) 2016 Bryon Aragam. All rights reserved.
#

#
# PACKAGE SPARSEBN: Main method for DAG estimation
#
#   CONTENTS:
#       estimate.dag
#       estimate.covariance
#       estimate.precision
#

#' Estimate a DAG from data
#'
#' Estimate the structure of a DAG (Bayesian network) from data. Works with any
#' combination of discrete / continuous and observational / experimental data.
#'
#' For details on the underlying methods, see \code{\link[ccdrAlgorithm]{ccdr.run}}
#' and \code{\link[discretecdAlgorithm]{cd.run}}.
#'
#' @param data Data as \code{\link[sparsebnUtils]{sparsebnData}}.
#' @param lambdas (optional) Numeric vector containing a grid of lambda values (i.e. regularization
#'                parameters) to use in the solution path. If missing, a default grid of values will be
#'                used based on a decreasing log-scale  (see also \link[sparsebnUtils]{generate.lambdas}).
#' @param lambdas.length Integer number of values to include in the solution path. If \code{lambdas}
#'                       has also been specified, this value will be ignored.
#' @param whitelist A two-column matrix of edges that are guaranteed to be in each
#'                  estimate (a "white list"). Each row in this matrix corresponds
#'                  to an edge that is to be whitelisted. These edges can be
#'                  specified by node name (as a \code{character} matrix), or by
#'                  index (as a \code{numeric} matrix).
#' @param blacklist A two-column matrix of edges that are guaranteed to be absent
#'                  from each estimate (a "black list"). See argument
#'                  "\code{whitelist}" above for more details.
#' @param error.tol Error tolerance for the algorithm, used to test for convergence.
#' @param max.iters Maximum number of iterations for each internal sweep.
#' @param edge.threshold Threshold parameter used to terminate the algorithm whenever the number of edges in the
#'              current estimate has \code{> edge.threshold} edges. NOTE: This is not the same as \code{alpha} in
#'              \code{\link[ccdrAlgorithm]{ccdr.run}}.
#' @param concavity (CCDr only) Value of concavity parameter. If \code{gamma > 0}, then the MCP will be used
#'              with \code{gamma} as the concavity parameter. If \code{gamma < 0}, then the L1 penalty
#'              will be used and this value is otherwise ignored.
#' @param weight.scale (CD only) A postitive number to scale weight matrix.
#' @param convLb (CD only) Small positive number used in Hessian approximation.
#' @param upperbound (CD only) A large positive value used to truncate the adaptive weights. A -1 value indicates that there is no truncation.
#' @param adaptive (CD only) \code{TRUE / FALSE}, if \code{TRUE} the adaptive algorithm will be run.
#' @param verbose \code{TRUE / FALSE} whether or not to print out progress and summary reports.
#'
#' @return A \code{\link[sparsebnUtils]{sparsebnPath}} object.
#'
#' @examples
#'
#' # Estimate a DAG from the cytometry data
#' data(cytometryContinuous)
#' dat <- sparsebnData(cytometryContinuous$data, type = "c", ivn = cytometryContinuous$ivn)
#' estimate.dag(dat)
#'
#' @export
estimate.dag <- function(data,
                         lambdas = NULL,
                         lambdas.length = 20,
                         whitelist = NULL,
                         blacklist = NULL,
                         error.tol = 1e-4,
                         max.iters = NULL,
                         edge.threshold = NULL,
                         concavity = 2.0,
                         weight.scale = 1.0,
                         convLb = 0.01,
                         upperbound = 100.0,
                         adaptive = FALSE,
                         verbose = FALSE
){
    pp <- ncol(data$data)

    ### Check for missing values
    num_missing_values <- sparsebnUtils::count_nas(data$data)
    if(num_missing_values > 0){
        stop(warning(has_missing_values(num_missing_values))) # this is an error, not a warning! (compare sparsebnData constructor)
    }

    ### Set edge threshold (alpha in paper)
    if(is.null(edge.threshold)){
        alpha <- sparsebnUtils::default_alpha() # by default, stop when nedge > 10*pp
    } else{
        alpha <- edge.threshold / pp
    }

    ### Set default value for maximum number of iterations run in algorithms
    if(is.null(max.iters)){
        max.iters <- sparsebnUtils::default_max_iters(pp)
    }

    ### Is the data gaussian, binomial, or multinomial? (Other data not supported yet.)
    data_family <- sparsebnUtils::pick_family(data)

    ### If intervention list contains character names, convert to indices
    if("character" %in% sparsebnUtils::list_classes(data$ivn)){
        data$ivn <- lapply(data$ivn, function(x){
            idx <- match(x, names(data$data))
            if(length(idx) == 0) NULL # return NULL if no match (=> observational)
            else idx
        })
    }

    ### Run the main algorithms
    if(data_family == "gaussian"){
        ccdrAlgorithm::ccdr.run(data = data,
                                lambdas = lambdas,
                                lambdas.length = lambdas.length,
                                whitelist = whitelist,
                                blacklist = blacklist,
                                gamma = concavity,
                                error.tol = error.tol,
                                max.iters = max.iters,
                                alpha = alpha,
                                verbose = verbose)
    } else if(data_family == "binomial" || data_family == "multinomial"){
        ### Note that interventions are automatically handled by this method, if present
        discretecdAlgorithm::cd.run(indata = data,
                                    lambdas = lambdas,
                                    lambdas.length = lambdas.length,
                                    whitelist = whitelist,
                                    blacklist = blacklist,
                                    error.tol = error.tol,
                                    convLb = convLb,
                                    weight.scale = weight.scale,
                                    upperbound = upperbound,
                                    adaptive = adaptive)
    }
}

#' Covariance estimation
#'
#' Methods for inferring (i) Covariance matrices and (ii) Precision matrices for continuous,
#' Gaussian data.
#'
#' For Gaussian data, the precision matrix corresponds to an undirected graphical model for the
#' distribution. This undirected graph can be tied to the corresponding directed graphical model;
#' see Sections 2.1 and 2.2 (equation (6)) of Aragam and Zhou (2015) for more details.
#'
#' @param data data as \code{\link{sparsebnData}} object.
#' @param ... (optional) additional parameters to \code{\link[sparsebn]{estimate.dag}}
#'
#' @return
#' Solution path as a plain \code{\link{list}}. Each component is a \code{\link[Matrix]{Matrix}}
#' corresponding to an estimate of the covariance or precision (inverse covariance) matrix for a
#' given value of lambda.
#'
#' @examples
#'
#' data(cytometryContinuous)
#' dat <- sparsebnData(cytometryContinuous$data, type = "c", ivn = cytometryContinuous$ivn)
#' estimate.covariance(dat) # estimate covariance
#' estimate.precision(dat)  # estimate precision
#'
#' @name estimate.covariance
#' @rdname estimate.covariance
NULL

#' @rdname estimate.covariance
#' @export
estimate.covariance <- function(data, ...){
    stopifnot(sparsebnUtils::is.sparsebnData(data))
    if(data$type != "continuous"){
        stop(sparsebnUtils::feature_not_supported("Covariance estimation for discrete models"))
    }

    estimated.dags <- estimate.dag(data, ...)
    sparsebnUtils::get.covariance(estimated.dags, data)
}

#' @rdname estimate.covariance
#' @export
estimate.precision <- function(data, ...){
    stopifnot(sparsebnUtils::is.sparsebnData(data))
    if(data$type != "continuous"){
        stop(sparsebnUtils::feature_not_supported("Precision matrix estimation for discrete models"))
    }

    estimated.dags <- estimate.dag(data, ...)
    sparsebnUtils::get.precision(estimated.dags, data)
}
