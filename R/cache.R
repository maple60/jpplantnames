CHECKLIST_URL <- "https://gbif.jp/activities/checklist/wamei_checklist_110/excel/wamei_checklist_ver.1.10.xlsx"
CHECKLIST_CACHE_FILE <- "wamei_checklist_ver.1.10.xlsx"

checklist_source_url <- function() {
  getOption("ylistjp.source_url", CHECKLIST_URL)
}

checklist_cache_dir <- function() {
  cache_dir <- getOption("ylistjp.cache_dir", NULL)
  if (!is.null(cache_dir)) {
    return(cache_dir)
  }

  tools::R_user_dir("ylistjp", which = "cache")
}

checklist_cache_path <- function() {
  file.path(checklist_cache_dir(), CHECKLIST_CACHE_FILE)
}

is_probably_url <- function(x) {
  grepl("^[A-Za-z][A-Za-z0-9+.-]*://", x)
}

#' Download the Japanese-name checklist data file
#'
#' Downloads the Vascular Plant Japanese Name Checklist ver. 1.10 Excel file
#' into the user's R cache. The file is not bundled with the package.
#'
#' @param overwrite Logical. If `FALSE`, an existing cached file is reused.
#'
#' @return The path to the cached file, invisibly.
#' @export
japanese_name_download <- function(overwrite = FALSE) {
  checklist_download(overwrite = overwrite)
}

#' @export
ylist_download <- function(overwrite = FALSE) {
  .Deprecated("japanese_name_download")
  japanese_name_download(overwrite = overwrite)
}

checklist_download <- function(overwrite = FALSE) {
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  path <- checklist_cache_path()
  if (file.exists(path) && !overwrite) {
    return(invisible(path))
  }

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  source <- checklist_source_url()
  tmp <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmp), add = TRUE)

  if (!is_probably_url(source) && file.exists(source)) {
    ok <- file.copy(source, tmp, overwrite = TRUE)
    if (!ok) {
      stop("Failed to copy local checklist source file.", call. = FALSE)
    }
  } else {
    status <- utils::download.file(
      url = source,
      destfile = tmp,
      mode = "wb",
      quiet = TRUE
    )
    if (!identical(status, 0L)) {
      stop("Failed to download checklist data from ", source, call. = FALSE)
    }
  }

  ok <- file.copy(tmp, path, overwrite = TRUE)
  if (!ok) {
    stop("Failed to write checklist data to cache: ", path, call. = FALSE)
  }

  invisible(path)
}
