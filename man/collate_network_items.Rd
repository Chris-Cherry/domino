% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convenience_fxns.R
\name{collate_network_items}
\alias{collate_network_items}
\title{Extracts all features, receptors, or ligands present in a signaling network.}
\usage{
collate_network_items(dom, clusters = NULL, return = NULL)
}
\arguments{
\item{dom}{A domino object containing a signaling network (i.e. build_domino run)}

\item{clusters}{A vector indicating clusters to collate network items from. If left as NULL then all clusters will be included.}

\item{return}{A string indicating where to collate 'features', 'receptors', or 'ligands'. If 'all' then a list of all three will be returned.}
}
\value{
A vector containing all features, receptors, or ligands in the data set or a list containing all three.
}
\description{
This function collates all of the features, receptors, or ligands found in a
signaling network anywhere in a list of clusters. This can be useful for
comparing signaling networks across two separate conditions. In order to run
this build_domino must be run on the object previously.
}
