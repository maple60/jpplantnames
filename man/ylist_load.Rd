\name{ylist_load}
\alias{ylist_load}
\title{Load cached Japanese-name checklist data}
\usage{
ylist_load(refresh = FALSE)
}
\arguments{
\item{refresh}{Logical. If \code{TRUE}, redownload the checklist data before
loading.}
}
\value{
A data frame containing normalized checklist rows.
}
\description{
Loads the cached Vascular Plant Japanese Name Checklist ver. 1.10 as a data
frame normalized for the package lookup helpers. If the cache does not exist,
the checklist file is downloaded first.
}
