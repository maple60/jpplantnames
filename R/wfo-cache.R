wfo_cache_dir <- function() {
  cache_dir <- getOption("jpplantnames.wfo_cache_dir", NULL)
  if (!is.null(cache_dir)) {
    return(cache_dir)
  }

  file.path(tools::R_user_dir("jpplantnames", which = "cache"), "wfo")
}

wfo_cache_file <- function(function_name,
                           scientific_name,
                           endpoint = wfo_endpoint(),
                           limit = 10) {
  key <- paste(function_name, endpoint, limit, scientific_name, sep = "\n")
  safe_name <- wfo_safe_filename_part(scientific_name)
  hash <- wfo_hash_string(key)

  file.path(
    wfo_cache_dir(),
    paste0(function_name, "_", safe_name, "_limit", limit, "_", hash, ".json")
  )
}

wfo_read_cache <- function(path) {
  if (!file.exists(path)) {
    return(NULL)
  }

  wfo_require_jsonlite("reading WFO cache files")
  tryCatch(
    jsonlite::read_json(path, simplifyVector = FALSE),
    error = function(error) NULL
  )
}

wfo_write_cache <- function(path, response) {
  wfo_require_jsonlite("writing WFO cache files")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    response,
    path = path,
    auto_unbox = TRUE,
    null = "null",
    pretty = TRUE
  )

  invisible(path)
}

wfo_safe_filename_part <- function(x) {
  safe <- iconv(enc2utf8(x), to = "ASCII//TRANSLIT", sub = "_")
  if (is.na(safe)) {
    safe <- "name"
  }

  safe <- gsub("[^A-Za-z0-9]+", "_", safe)
  safe <- gsub("^_+|_+$", "", safe)
  if (identical(safe, "")) {
    safe <- "name"
  }

  substr(safe, 1, 60)
}

wfo_hash_string <- function(x) {
  bytes <- as.integer(charToRaw(enc2utf8(x)))
  if (length(bytes) == 0) {
    return("00000000")
  }

  value <- sum((bytes + 1) * seq_along(bytes)) %% 2147483647
  sprintf("%08x", as.integer(value))
}
