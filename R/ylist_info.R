#' Get a high-level YList summary for Japanese plant names
#'
#' `ylist_info()` is a convenient wrapper for users who want a compact,
#' browser-like summary from a Japanese plant name. It keeps the cached
#' Japanese-name checklist lookup separate from WFO or GBIF checks, which are
#' only run when explicitly requested.
#'
#' @param name Character vector of Japanese plant names.
#' @param with_author Logical. If `TRUE`, print and return WFO accepted names
#'   with authors where available.
#' @param wfo Logical. If `TRUE`, check the preferred checklist scientific name
#'   with [wfo_accepted_name()].
#' @param gbif Logical. If `TRUE`, check the preferred checklist scientific name
#'   with [gbif_match()].
#' @param rank Character scalar rank to prefer for WFO checks.
#' @param limit Integer. Maximum number of WFO suggestions to request per
#'   unique scientific name.
#' @param cache Logical. If `TRUE`, use the existing WFO response cache.
#' @param refresh Logical. If `TRUE`, ignore existing cached WFO responses.
#' @param delay Numeric. Seconds to wait between uncached WFO API requests.
#' @param ... Additional arguments passed to [wfo_accepted_name()] when
#'   `wfo = TRUE`.
#'
#' @return A named list with class `"ylist_info"` containing `query`,
#'   `summary`, `ylist`, `wfo`, and `gbif`. The `ylist` element keeps the
#'   historical API name and contains checklist candidate rows.
#' @export
#'
#' @examples
#' \dontrun{
#' ylist_info("\u30b3\u30ca\u30e9")
#' ylist_info(c("\u30b3\u30ca\u30e9", "\u30df\u30ba\u30ca\u30e9"))
#'
#' ylist_info("\u30b3\u30ca\u30e9", wfo = TRUE)
#' ylist_info("\u30b3\u30ca\u30e9", wfo = TRUE, gbif = TRUE)
#' }
ylist_info <- function(name,
                       with_author = TRUE,
                       wfo = FALSE,
                       gbif = FALSE,
                       rank = "species",
                       limit = 10,
                       cache = TRUE,
                       refresh = FALSE,
                       delay = 0.2,
                       ...) {
  if (!is.character(name)) {
    stop("`name` must be a character vector.", call. = FALSE)
  }

  with_author <- wfo_check_logical(with_author, "with_author")
  wfo <- wfo_check_logical(wfo, "wfo")
  gbif <- wfo_check_logical(gbif, "gbif")
  rank <- wfo_check_rank(rank)
  limit <- wfo_check_limit(limit)
  cache <- wfo_check_logical(cache, "cache")
  refresh <- wfo_check_logical(refresh, "refresh")
  delay <- wfo_check_delay(delay)

  summary <- ylist_info_empty_summary(name)
  ylist_candidates <- vector("list", length(name))

  for (i in seq_along(name)) {
    input <- name[[i]]
    if (ylist_info_invalid_input(input)) {
      summary$match_status[[i]] <- "invalid_input"
      next
    }

    query <- trimws(input)
    rows <- ylist_search(query, field = "japanese", exact = TRUE)
    n_candidates <- nrow(rows)
    summary$n_ylist_candidates[[i]] <- n_candidates

    if (n_candidates == 0L) {
      summary$match_status[[i]] <- "no_ylist_match"
      next
    }

    standard_indices <- which(
      rows[[col_japanese_name]] == query &
        rows[[col_status]] == status_standard
    )

    preferred_index <- NA_integer_
    if (
      length(standard_indices) == 1L ||
        (length(standard_indices) > 1L && is_wamei_checklist_data(rows))
    ) {
      preferred_index <- standard_indices[[1]]
      preferred <- rows[preferred_index, , drop = FALSE]

      summary$matched[[i]] <- TRUE
      summary$japanese_name[[i]] <- ylist_info_cell(preferred, col_japanese_name)
      summary$scientific_name[[i]] <- ylist_info_cell(preferred, col_scientific_name)
      summary$scientific_name_with_author[[i]] <- ylist_info_cell(
        preferred,
        col_scientific_name_author
      )
      summary$match_status[[i]] <- "matched"
    } else if (length(standard_indices) > 1L) {
      summary$match_status[[i]] <- "ambiguous_standard_match"
    } else {
      summary$match_status[[i]] <- "no_standard_match"
    }

    ylist_candidates[[i]] <- ylist_info_candidate_rows(
      rows = rows,
      input = input,
      query = query,
      input_index = i,
      preferred_index = preferred_index
    )
  }

  ylist_rows <- ylist_candidates[lengths(ylist_candidates) > 0L]
  ylist_rows <- if (length(ylist_rows) == 0L) {
    ylist_info_empty_ylist()
  } else {
    do.call(rbind, ylist_rows)
  }
  row.names(ylist_rows) <- NULL

  wfo_rows <- NULL
  if (wfo) {
    wfo_rows <- ylist_info_call_wfo(
      summary$scientific_name,
      with_author = with_author,
      rank = rank,
      limit = limit,
      cache = cache,
      refresh = refresh,
      delay = delay,
      ...
    )
    summary$wfo_accepted_name <- ylist_info_column(
      wfo_rows,
      "accepted_name",
      length(name)
    )
    summary$wfo_accepted_name_no_author <- ylist_info_column(
      wfo_rows,
      "accepted_name_no_author",
      length(name)
    )
    summary$wfo_accepted_wfo_id <- ylist_info_column(
      wfo_rows,
      "accepted_wfo_id",
      length(name)
    )
    summary$wfo_match_status <- ylist_info_column(
      wfo_rows,
      "match_status",
      length(name)
    )
  }

  gbif_rows <- NULL
  if (gbif) {
    gbif_rows <- ylist_info_call_gbif(summary$scientific_name)
    summary$gbif_usage_key <- ylist_info_column(
      gbif_rows,
      "usageKey",
      length(name),
      default = NA
    )
    summary$gbif_scientific_name <- ylist_info_column(
      gbif_rows,
      "scientificName",
      length(name)
    )
    summary$gbif_status <- ylist_info_column(gbif_rows, "status", length(name))
    summary$gbif_match_type <- ylist_info_column(
      gbif_rows,
      "matchType",
      length(name)
    )
  }

  result <- list(
    query = name,
    summary = summary,
    ylist = ylist_rows,
    wfo = wfo_rows,
    gbif = gbif_rows
  )
  attr(result, "with_author") <- with_author
  class(result) <- "ylist_info"
  result
}

#' @export
print.ylist_info <- function(x, ...) {
  summary <- x$summary
  with_author <- isTRUE(attr(x, "with_author"))

  if (nrow(summary) == 1L) {
    scientific_name <- ylist_info_display_scientific(summary, with_author)[[1]]

    cat("YList info: ", ylist_info_print_value(summary$input[[1]]), "\n\n", sep = "")
    cat("YList:\n")
    cat("  Scientific name: ", ylist_info_print_value(scientific_name), "\n", sep = "")
    cat("  Candidates: ", summary$n_ylist_candidates[[1]], "\n", sep = "")
    cat("  Status: ", ylist_info_print_value(summary$match_status[[1]]), "\n", sep = "")

    if (!is.null(x$wfo)) {
      cat("\nWFO:\n")
      cat(
        "  Accepted name: ",
        ylist_info_print_value(summary$wfo_accepted_name[[1]]),
        "\n",
        sep = ""
      )
      cat(
        "  Status: ",
        ylist_info_print_value(summary$wfo_match_status[[1]]),
        "\n",
        sep = ""
      )
    }

    if (!is.null(x$gbif)) {
      cat("\nGBIF:\n")
      cat(
        "  Scientific name: ",
        ylist_info_print_value(summary$gbif_scientific_name[[1]]),
        "\n",
        sep = ""
      )
      cat(
        "  Status: ",
        ylist_info_print_value(summary$gbif_status[[1]]),
        "\n",
        sep = ""
      )
    }
  } else {
    cat("YList info: ", nrow(summary), " queries\n\n", sep = "")
    display <- data.frame(
      input = summary$input,
      scientific_name = ylist_info_display_scientific(summary, with_author),
      match_status = summary$match_status,
      stringsAsFactors = FALSE
    )
    print(display, row.names = FALSE, na.print = "NA")
  }

  cat("\nUse x$summary, x$ylist, x$wfo, and x$gbif for data frames.\n")
  invisible(x)
}

ylist_info_empty_summary <- function(name) {
  n <- length(name)
  data.frame(
    input = name,
    matched = rep(FALSE, n),
    japanese_name = rep(NA_character_, n),
    scientific_name = rep(NA_character_, n),
    scientific_name_with_author = rep(NA_character_, n),
    n_ylist_candidates = rep(0L, n),
    match_status = rep(NA_character_, n),
    wfo_accepted_name = rep(NA_character_, n),
    wfo_accepted_name_no_author = rep(NA_character_, n),
    wfo_accepted_wfo_id = rep(NA_character_, n),
    wfo_match_status = rep(NA_character_, n),
    gbif_usage_key = rep(NA, n),
    gbif_scientific_name = rep(NA_character_, n),
    gbif_status = rep(NA_character_, n),
    gbif_match_type = rep(NA_character_, n),
    stringsAsFactors = FALSE
  )
}

ylist_info_empty_ylist <- function() {
  out <- data.frame(
    input_index = integer(),
    input = character(),
    query = character(),
    is_preferred = logical(),
    stringsAsFactors = FALSE
  )

  for (column in required_ylist_columns) {
    out[[column]] <- character()
  }

  out
}

ylist_info_candidate_rows <- function(rows,
                                      input,
                                      query,
                                      input_index,
                                      preferred_index) {
  out <- data.frame(
    input_index = rep(input_index, nrow(rows)),
    input = rep(input, nrow(rows)),
    query = rep(query, nrow(rows)),
    is_preferred = rep(FALSE, nrow(rows)),
    rows,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  if (!is.na(preferred_index)) {
    out$is_preferred[[preferred_index]] <- TRUE
  }

  row.names(out) <- NULL
  out
}

ylist_info_invalid_input <- function(x) {
  is.na(x) || trimws(x) == ""
}

ylist_info_cell <- function(row, column) {
  if (!(column %in% names(row))) {
    return(NA_character_)
  }

  value <- row[[column]][[1]]
  if (length(value) == 0L || is.na(value) || identical(value, "")) {
    return(NA_character_)
  }

  as.character(value)
}

ylist_info_call_wfo <- function(scientific_name,
                                with_author,
                                rank,
                                limit,
                                cache,
                                refresh,
                                delay,
                                ...) {
  tryCatch(
    wfo_accepted_name(
      scientific_name,
      rank = rank,
      with_author = with_author,
      limit = limit,
      cache = cache,
      refresh = refresh,
      delay = delay,
      ...
    ),
    error = function(error) {
      warning("WFO lookup failed: ", conditionMessage(error), call. = FALSE)
      ylist_info_wfo_error_rows(scientific_name, conditionMessage(error))
    }
  )
}

ylist_info_call_gbif <- function(scientific_name) {
  tryCatch(
    {
      matcher <- getOption("ylistjp.gbif_match", gbif_match)
      matcher(scientific_name)
    },
    error = function(error) {
      warning("GBIF lookup failed: ", conditionMessage(error), call. = FALSE)
      ylist_info_gbif_error_rows(scientific_name, conditionMessage(error))
    }
  )
}

ylist_info_wfo_error_rows <- function(scientific_name, message) {
  if (length(scientific_name) == 0L) {
    rows <- empty_wfo_accepted_row(NA_character_, "error")[0, , drop = FALSE]
    rows$error <- character()
    return(rows)
  }

  rows <- lapply(scientific_name, function(input) {
    row <- empty_wfo_accepted_row(input, "error")
    row$error <- message
    row
  })
  rows <- do.call(rbind, rows)
  row.names(rows) <- NULL
  rows
}

ylist_info_gbif_error_rows <- function(scientific_name, message) {
  if (length(scientific_name) == 0L) {
    rows <- empty_gbif_row(NA_character_)[0, , drop = FALSE]
    rows$error <- character()
    return(rows)
  }

  rows <- lapply(scientific_name, function(input) {
    row <- empty_gbif_row(input)
    row$status <- "error"
    row$error <- message
    row
  })
  rows <- do.call(rbind, rows)
  row.names(rows) <- NULL
  rows
}

ylist_info_column <- function(data, column, n, default = NA_character_) {
  if (is.null(data) || !(column %in% names(data))) {
    return(rep(default, n))
  }

  values <- data[[column]]
  if (length(values) != n) {
    return(rep(default, n))
  }

  values
}

ylist_info_display_scientific <- function(summary, with_author) {
  if (with_author) {
    values <- summary$scientific_name_with_author
    missing <- is.na(values) | values == ""
    values[missing] <- summary$scientific_name[missing]
    return(values)
  }

  summary$scientific_name
}

ylist_info_print_value <- function(x) {
  if (length(x) == 0L || is.na(x)) {
    return("NA")
  }
  if (identical(x, "")) {
    return("\"\"")
  }

  as.character(x)
}
