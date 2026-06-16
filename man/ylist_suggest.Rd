\name{ylist_suggest}
\alias{ylist_suggest}
\title{Suggest lookup rows for an approximate Japanese plant name}
\usage{
ylist_suggest(query, n = 10, max_distance = NULL)
}
\arguments{
\item{query}{Character scalar Japanese plant name to search for.}

\item{n}{Maximum number of candidate rows to return.}

\item{max_distance}{Maximum string distance for fuzzy matches. If \code{NULL},
the default is 1 for normalized queries with 3 or fewer characters and 2
for longer queries.}
}
\value{
A data frame containing lookup rows plus \code{query}, \code{matched_value},
\code{distance}, \code{score}, and \code{match_type}.
}
\description{
\code{ylist_suggest()} is a small interactive helper for finding likely lookup
rows before converting Japanese names to scientific names. It searches only
the cached lookup Japanese-name column and does not change or autocorrect
\code{\link[=academic_name]{academic_name()}} results.
}
\examples{
\dontrun{
ylist_suggest("\u30b3\u30ca\u30e9")
ylist_suggest("\u30ca\u30e9")
}
}
