\name{wfo_accepted_name}
\alias{wfo_accepted_name}
\title{Return the best accepted WFO Plant List name}
\usage{
wfo_accepted_name(
  scientific_name,
  rank = "species",
  with_author = TRUE,
  limit = 10,
  cache = TRUE,
  refresh = FALSE,
  delay = 0.2,
  backend = c("api", "local")
)
}
\arguments{
\item{scientific_name}{Character vector of scientific names.}

\item{rank}{Character scalar rank to prefer, usually \code{"species"}.}

\item{with_author}{Logical. If \code{TRUE}, return the accepted name with
authors when available. If \code{FALSE}, return the no-author accepted name in
\code{accepted_name}.}

\item{limit}{Integer. Maximum number of WFO suggestions to request per unique
scientific name.}

\item{cache}{Logical. If \code{TRUE}, raw API responses are cached locally.}

\item{refresh}{Logical. If \code{TRUE}, ignore an existing cached response and
fetch from the WFO API again.}

\item{delay}{Numeric. Seconds to wait between uncached API requests.}

\item{backend}{Character. Only \code{"api"} is implemented. \code{"local"} is
reserved for future WFO release support.}
}
\value{
A data frame with one row per input and a clear \code{match_status}.
}
\description{
Summarise WFO Plant List suggestions into one accepted-name interpretation per
input scientific name. Lookup functions such as
\code{\link[=scientific_name]{scientific_name()}} handle Japanese name to scientific
name lookup; this helper handles scientific name to WFO candidate, accepted
name, WFO ID, rank, and status checks.
}
\details{
WFO API access is intended for small-scale interactive checks. These functions
do not automatically replace checklist names with WFO accepted names. Accepted
names are database- and release-dependent.
}
\examples{
\dontrun{
wfo_accepted_name("Quercus serrata")
wfo_accepted_name("Quercus serrata", with_author = FALSE)
wfo_accepted_name(scientific_name("コナラ"))
}
}
