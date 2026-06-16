write_ylist_fixture <- function(path) {
  write_zip_store(path, xlsx_fixture_files(wamei_fixture_sheets()))
}

wamei_fixture_sheets <- function() {
  konara <- "\u30b3\u30ca\u30e9"
  nara <- "\u30ca\u30e9"
  hahaso <- "\u30cf\u30cf\u30bd"
  mizunara <- "\u30df\u30ba\u30ca\u30e9"
  oobakonara <- "\u30aa\u30aa\u30d0\u30b3\u30ca\u30e9"
  buna <- "\u30d6\u30ca"

  list(
    Hub_data = list(
      c(
        "all_name", "Hub name", "lato/stricto", "Family ID",
        "Family name", "Family name (JP)", "GL", "SF", "WF", "YL",
        "status", "message"
      ),
      c(
        konara, konara, "\u5e83\u7fa9", "216", "Fagaceae", buna,
        "GL_05174", "#N/A", "#N/A", "YL_09842", "\u78ba\u5b9a",
        "\u30b3\u30ca\u30e9\u5e83\u7fa9/\u72ed\u7fa9"
      ),
      c(
        nara, konara, "\u5e83\u7fa9", "216", "Fagaceae", buna,
        "GL_05174", "#N/A", "#N/A", "YL_09842", "\u78ba\u5b9a", ""
      ),
      c(
        hahaso, konara, "\u5e83\u7fa9", "216", "Fagaceae", buna,
        "GL_05174", "#N/A", "#N/A", "YL_09842", "\u78ba\u5b9a", ""
      )
    ),
    JN_dataset = list(
      c(
        "ID", "Family ID", "Family name", "Family name (JP)",
        "common name", "another name", "another name ID", "note 1",
        "note 2", "scientific name with author",
        "scientific name without author"
      ),
      c(
        "GL_05174", "216", "Fagaceae", buna, konara, konara, "0",
        "", "", "Quercus serrata Murray", "Quercus serrata"
      ),
      c(
        "GL_05174", "216", "Fagaceae", buna, konara, nara, "2",
        "", "", "Quercus serrata Murray", "Quercus serrata"
      ),
      c(
        "WF_03882", "216", "Fagaceae", buna, konara, konara, "0",
        "", "", "Quercus serrata Murray subsp. serrata var. serrata",
        "Quercus serrata subsp. serrata var. serrata"
      ),
      c(
        "WF_03882", "216", "Fagaceae", buna, konara, hahaso, "1",
        "", "", "Quercus serrata Murray subsp. serrata var. serrata",
        "Quercus serrata subsp. serrata var. serrata"
      ),
      c(
        "WF_03884", "216", "Fagaceae", buna, mizunara, mizunara, "0",
        "", "", "Quercus crispula Blume", "Quercus crispula"
      ),
      c(
        "WF_03892", "216", "Fagaceae", buna, oobakonara, oobakonara,
        "0", "", "", "Quercus \u00d7 major Nakai", "Quercus \u00d7 major"
      )
    ),
    errata = list(
      c(
        "sheet", "ID", "colmun", "erratum", "correct",
        "correction date", "Acknowledgments for"
      )
    )
  )
}

xlsx_fixture_files <- function(sheets) {
  shared <- unique(unlist(sheets, use.names = FALSE))

  files <- list(
    "[Content_Types].xml" = paste0(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
      '<Default Extension="xml" ContentType="application/xml"/>',
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
      '<Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
      '<Override PartName="/xl/worksheets/sheet3.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
      '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>',
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>',
      "</Types>"
    ),
    "_rels/.rels" = paste0(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>',
      "</Relationships>"
    ),
    "xl/workbook.xml" = workbook_xml(names(sheets)),
    "xl/_rels/workbook.xml.rels" = workbook_rels_xml(length(sheets)),
    "xl/sharedStrings.xml" = shared_strings_xml(shared, sheets),
    "xl/styles.xml" = paste0(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
      '<fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>',
      '<fills count="1"><fill><patternFill patternType="none"/></fill></fills>',
      '<borders count="1"><border/></borders>',
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>',
      '<cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>',
      "</styleSheet>"
    )
  )

  for (i in seq_along(sheets)) {
    files[[paste0("xl/worksheets/sheet", i, ".xml")]] <-
      worksheet_xml(sheets[[i]], shared)
  }

  lapply(files, function(x) charToRaw(enc2utf8(x)))
}

workbook_xml <- function(sheet_names) {
  sheets <- vapply(seq_along(sheet_names), function(i) {
    paste0(
      '<sheet name="', xml_escape(sheet_names[[i]]), '" sheetId="', i,
      '" r:id="rId', i, '"/>'
    )
  }, character(1))

  paste0(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" ',
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">',
    "<sheets>", paste0(sheets, collapse = ""), "</sheets></workbook>"
  )
}

workbook_rels_xml <- function(n_sheets) {
  sheet_rels <- vapply(seq_len(n_sheets), function(i) {
    paste0(
      '<Relationship Id="rId', i,
      '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" ',
      'Target="worksheets/sheet', i, '.xml"/>'
    )
  }, character(1))

  paste0(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
    paste0(sheet_rels, collapse = ""),
    '<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>',
    '<Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>',
    "</Relationships>"
  )
}

shared_strings_xml <- function(shared, sheets) {
  strings <- vapply(shared, function(value) {
    paste0("<si><t>", xml_escape(value), "</t></si>")
  }, character(1))

  paste0(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
    '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" ',
    'count="', length(unlist(sheets, use.names = FALSE)), '" ',
    'uniqueCount="', length(shared), '">',
    paste0(strings, collapse = ""),
    "</sst>"
  )
}

worksheet_xml <- function(rows, shared) {
  body <- vapply(seq_along(rows), function(i) {
    row <- rows[[i]]
    cells <- vapply(seq_along(row), function(j) {
      paste0(
        '<c r="', xlsx_col(j), i, '" t="s"><v>',
        match(row[[j]], shared) - 1L,
        "</v></c>"
      )
    }, character(1))
    paste0('<row r="', i, '">', paste0(cells, collapse = ""), "</row>")
  }, character(1))

  paste0(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" ',
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">',
    "<sheetData>", paste0(body, collapse = ""), "</sheetData></worksheet>"
  )
}

xlsx_col <- function(index) {
  out <- character()
  while (index > 0L) {
    index <- index - 1L
    out <- c(intToUtf8(65L + index %% 26L), out)
    index <- index %/% 26L
  }
  paste0(out, collapse = "")
}

xml_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

write_zip_store <- function(path, files) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)

  central <- vector("list", length(files))
  offset <- 0

  for (i in seq_along(files)) {
    name_raw <- charToRaw(names(files)[[i]])
    data <- files[[i]]
    crc <- zip_crc32(data)
    size <- length(data)
    header <- c(
      uint_le(0x04034b50, 4), uint_le(20, 2), uint_le(0, 2),
      uint_le(0, 2), uint_le(0, 2), uint_le(33, 2), uint_le(crc, 4),
      uint_le(size, 4), uint_le(size, 4), uint_le(length(name_raw), 2),
      uint_le(0, 2), name_raw
    )

    writeBin(header, con)
    writeBin(data, con)
    central[[i]] <- list(name = name_raw, crc = crc, size = size, offset = offset)
    offset <- offset + length(header) + size
  }

  central_offset <- offset
  for (entry in central) {
    header <- c(
      uint_le(0x02014b50, 4), uint_le(20, 2), uint_le(20, 2),
      uint_le(0, 2), uint_le(0, 2), uint_le(0, 2), uint_le(33, 2),
      uint_le(entry$crc, 4), uint_le(entry$size, 4), uint_le(entry$size, 4),
      uint_le(length(entry$name), 2), uint_le(0, 2), uint_le(0, 2),
      uint_le(0, 2), uint_le(0, 2), uint_le(0, 4),
      uint_le(entry$offset, 4), entry$name
    )
    writeBin(header, con)
    offset <- offset + length(header)
  }

  central_size <- offset - central_offset
  end <- c(
    uint_le(0x06054b50, 4), uint_le(0, 2), uint_le(0, 2),
    uint_le(length(files), 2), uint_le(length(files), 2),
    uint_le(central_size, 4), uint_le(central_offset, 4), uint_le(0, 2)
  )
  writeBin(end, con)
}

uint_le <- function(x, bytes) {
  as.raw(floor(x / 256^(0:(bytes - 1L))) %% 256)
}

zip_crc32 <- function(x) {
  crc <- -1L
  for (byte in as.integer(x)) {
    idx <- bitwAnd(bitwXor(crc, byte), 255L) + 1L
    crc <- bitwXor(bitwShiftR(crc, 8L), zip_crc32_table()[[idx]])
  }

  out <- bitwXor(crc, -1L)
  if (out < 0) {
    out <- out + 2^32
  }
  out
}

zip_crc32_table <- local({
  table <- NULL

  function() {
    if (!is.null(table)) {
      return(table)
    }

    table <<- numeric(256)
    for (i in 0:255) {
      crc <- i
      for (j in 1:8) {
        crc <- if (bitwAnd(crc, 1L)) {
          bitwXor(bitwShiftR(crc, 1L), -306674912L)
        } else {
          bitwShiftR(crc, 1L)
        }
      }
      table[[i + 1L]] <<- crc
    }
    table
  }
})

with_fixture_cache <- function(code) {
  source <- tempfile(fileext = ".xlsx")
  cache_dir <- tempfile("ylistjp-cache-")
  write_ylist_fixture(source)

  old_options <- options(
    ylistjp.source_url = source,
    ylistjp.cache_dir = cache_dir,
    ylistjp.data = NULL
  )
  on.exit(options(old_options), add = TRUE)
  on.exit(unlink(c(source, cache_dir), recursive = TRUE, force = TRUE), add = TRUE)

  force(code)
}
