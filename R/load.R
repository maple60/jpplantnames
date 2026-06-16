#' Load cached Japanese-name checklist data
#'
#' Loads the cached Vascular Plant Japanese Name Checklist ver. 1.10 as a data
#' frame normalized for the package lookup helpers. If the cache does not
#' exist, the checklist file is downloaded first.
#'
#' @param refresh Logical. If `TRUE`, redownload the checklist data before
#'   loading.
#'
#' @return A data frame containing normalized checklist rows.
#' @export
japanese_name_load <- function(refresh = FALSE) {
  if (!isTRUE(refresh) && !identical(refresh, FALSE)) {
    stop("`refresh` must be TRUE or FALSE.", call. = FALSE)
  }

  path <- checklist_cache_path()
  if (refresh || !file.exists(path)) {
    checklist_download(overwrite = refresh)
  }

  read_checklist(path)
}

#' @export
ylist_load <- function(refresh = FALSE) {
  .Deprecated("japanese_name_load")
  japanese_name_load(refresh = refresh)
}

checklist_japanese_name_sheet <- "JN_dataset"

required_checklist_columns <- c(
  "ID",
  "Family ID",
  "Family name",
  "Family name (JP)",
  "common name",
  "another name",
  "another name ID",
  "note 1",
  "note 2",
  "scientific name with author",
  "scientific name without author"
)

read_checklist <- function(path) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop(
      "Package `readxl` is required to read the checklist Excel file. ",
      "Install it with install.packages(\"readxl\").",
      call. = FALSE
    )
  }

  data <- readxl::read_excel(
    path = path,
    sheet = checklist_japanese_name_sheet,
    col_types = "text",
    .name_repair = "minimal"
  )
  data <- as.data.frame(data, stringsAsFactors = FALSE, check.names = FALSE)
  names(data) <- normalize_checklist_column_names(names(data))

  normalize_checklist_japanese_name_dataset(data)
}

normalize_checklist_column_names <- function(x) {
  x <- enc2utf8(x)
  x <- sub("\ufeff", "", x, fixed = TRUE)
  trimws(x)
}

normalize_checklist_japanese_name_dataset <- function(data) {
  check_checklist_columns(data)

  out <- data.frame(
    .row_id = seq_len(nrow(data)),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  out[[col_scientific_name_author]] <-
    checklist_column(data, "scientific name with author")
  out[[col_japanese_name]] <- checklist_column(data, "common name")
  out[[col_alias_name]] <- checklist_column(data, "another name")
  out[[col_status]] <- rep(status_standard, nrow(data))
  out[["Family ID"]] <- checklist_column(data, "Family ID")
  out[["Family name"]] <- checklist_column(data, "Family name")
  out[["Family name (JP)"]] <- checklist_column(data, "Family name (JP)")
  out[[col_scientific_name]] <-
    checklist_column(data, "scientific name without author")
  out[["ID"]] <- checklist_column(data, "ID")
  out[["another name ID"]] <- checklist_column(data, "another name ID")
  out[["note 1"]] <- checklist_column(data, "note 1")
  out[["note 2"]] <- checklist_column(data, "note 2")
  out$.row_id <- NULL

  out$source_id <- out[["ID"]]
  out$source <- sub("_.*$", "", out$source_id)
  out
}

check_checklist_columns <- function(data, required = required_checklist_columns) {
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    stop(
      "Checklist data is missing required column(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(data)
}

checklist_column <- function(data, column) {
  values <- as.character(data[[column]])
  values[is.na(values)] <- ""
  enc2utf8(values)
}

japanese_name_data <- function() {
  data <- getOption("ylistjp.data", NULL)
  if (!is.null(data)) {
    return(data)
  }

  japanese_name_load()
}
