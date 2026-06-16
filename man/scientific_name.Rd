\name{scientific_name}
\alias{scientific_name}
\alias{academic_name}
\title{Look up scientific names from Japanese plant names}
\usage{
scientific_name(name, with_author = FALSE)

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
\details{
\code{academic_name()} is retained as a deprecated compatibility wrapper.
Use \code{scientific_name()} for new code.
}
\examples{
\dontrun{
scientific_name("コナラ")
scientific_name("コナラ", with_author = TRUE)
}
}
