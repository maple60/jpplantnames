\name{japanese_name_search}
\alias{japanese_name_search}
\alias{ylist_search}
\title{Search cached checklist rows}
\usage{
japanese_name_search(
  query,
  field = c("japanese", "scientific", "alias", "all"),
  exact = FALSE
)

ylist_search(
  query,
  field = c("japanese", "scientific", "alias", "all"),
  exact = FALSE
)
}
\arguments{
\item{query}{Character scalar to search for.}

\item{field}{Field to search: \code{japanese}, \code{scientific}, \code{alias}, or \code{all}.}

\item{exact}{Logical. If \code{TRUE}, use exact matching; otherwise use partial
fixed-string matching.}
}
\value{
A data frame of matching lookup rows.
}
\description{
Search cached checklist rows by Japanese name, scientific name, alias, or all
of those fields.
}
\details{
\code{ylist_search()} is retained as a deprecated compatibility wrapper.
Use \code{japanese_name_search()} for new code.
}
