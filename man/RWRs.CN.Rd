% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RWRs.CN.R
\name{RWRs.CN}
\alias{RWRs.CN}
\title{RWRs.CN function}
\usage{
RWRs.CN(nodes, edges, r = 0.8, core = 10)
}
\arguments{
\item{nodes}{data.frame, two columns:object,object label(0/1),0 represents candidate nodes and 1 represents known nodes(seeds).}

\item{edges}{data.frame, two columns:interactorA,interactorB,A and B have a certain interaction relationship.}

\item{r}{default 0.8,Restart probability of random walk,interval is (0,1),r is preferably above 0.5.}

\item{core}{default 10,Top percentile of ranking for candidates,interval is (0,100].Top core percent nodes and their edges will be extracted as core network.}
}
\description{
Measure the correlation of candidate nodes and known nodes
}
\author{
Fan Wang
}
