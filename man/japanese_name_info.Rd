\name{japanese_name_info}
\alias{japanese_name_info}
\alias{ylist_info}
\alias{print.japanese_name_info}
\alias{print.ylist_info}
\title{Get a high-level Japanese-name checklist summary}
\usage{
japanese_name_info(
  name,
  with_author = TRUE,
  wfo = FALSE,
  gbif = FALSE,
  rank = "species",
  limit = 10,
  cache = TRUE,
  refresh = FALSE,
  delay = 0.2,
  ...
)

\method{print}{japanese_name_info}(x, ...)

ylist_info(
  name,
  with_author = TRUE,
  wfo = FALSE,
  gbif = FALSE,
  rank = "species",
  limit = 10,
  cache = TRUE,
  refresh = FALSE,
  delay = 0.2,
  ...
)

\method{print}{ylist_info}(x, ...)
}
\arguments{
\item{name}{Character vector of Japanese plant names.}

\item{with_author}{Logical. If \code{TRUE}, print and return WFO accepted names
with authors where available.}

\item{wfo}{Logical. If \code{TRUE}, check the preferred checklist scientific name
with \code{\link[=wfo_accepted_name]{wfo_accepted_name()}}.}

\item{gbif}{Logical. If \code{TRUE}, check the preferred checklist scientific name
with \code{\link[=gbif_match]{gbif_match()}}.}

\item{rank}{Character scalar rank to prefer for WFO checks.}

\item{limit}{Integer. Maximum number of WFO suggestions to request per unique
scientific name.}

\item{cache}{Logical. If \code{TRUE}, use the existing WFO response cache.}

\item{refresh}{Logical. If \code{TRUE}, ignore existing cached WFO responses.}

\item{delay}{Numeric. Seconds to wait between uncached WFO API requests.}

\item{...}{Additional arguments passed to
\code{\link[=wfo_accepted_name]{wfo_accepted_name()}} when \code{wfo = TRUE}.}

\item{x}{A \code{japanese_name_info} object.}
}
\value{
A named list with class \code{"japanese_name_info"} containing:
\itemize{
\item \code{query}: the original input vector.
\item \code{summary}: one summary row per input name.
\item \code{japanese_name}: checklist candidate rows with input metadata.
\item \code{ylist}: deprecated compatibility alias for \code{japanese_name}.
\item \code{wfo}: WFO accepted-name rows, or \code{NULL}.
\item \code{gbif}: GBIF match rows, or \code{NULL}.
}
}
\description{
\code{japanese_name_info()} is a convenient wrapper for users who want a compact,
browser-like summary from a Japanese plant name. It keeps the cached
Japanese-name checklist lookup separate from WFO or GBIF checks, which are
only run when explicitly requested.
}
\details{
The summary keeps the preferred checklist match separate from optional WFO and
GBIF checks. Alternative checklist candidate rows are kept in
\code{x$japanese_name}; \code{x$ylist} is retained as a deprecated
compatibility alias.
WFO and GBIF results do not overwrite checklist names.

\code{ylist_info()} is retained as a deprecated compatibility wrapper.
Use \code{japanese_name_info()} for new code.
}
\examples{
\dontrun{
japanese_name_info("コナラ")
japanese_name_info(c("コナラ", "ミズナラ"))

japanese_name_info("コナラ", wfo = TRUE)
japanese_name_info("コナラ", wfo = TRUE, gbif = TRUE)
}
}
