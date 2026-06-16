\name{ylist_download}
\alias{ylist_download}
\title{Download the Japanese-name checklist data file}
\usage{
ylist_download(overwrite = FALSE)
}
\arguments{
\item{overwrite}{Logical. If \code{FALSE}, an existing cached file is reused.}
}
\value{
The path to the cached file, invisibly.
}
\description{
Downloads the Vascular Plant Japanese Name Checklist ver. 1.10 Excel file
into the user's R cache. The file is not bundled with the package.
}
