\name{academic_name}
\alias{academic_name}
\title{Look up scientific names from Japanese plant names}
\usage{
academic_name(name, with_author = FALSE)
}
\arguments{
\item{name}{Character vector of Japanese plant names.}

\item{with_author}{Logical. If \code{TRUE}, return \code{学名 withAuthor};
otherwise return \code{学名}.}
}
\value{
A character vector with one result per input name. Missing names return
\code{NA_character_}.
}
\description{
Exact-matches Japanese names in the cached checklist data and returns the
scientific name.
}
\examples{
\dontrun{
academic_name("コナラ")
academic_name("コナラ", with_author = TRUE)
}
}
