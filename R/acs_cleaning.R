library(data.table)

default_checkpoint_map <- function() {
  c(
    O_1_message = "message",
    O_2_SOUNDTEST = "soundtest",
    O_3_maximize_message = "maximize",
    O_4_video_element1 = "video",
    O_5_video_element2 = "video",
    O_40_message = "message",
    O_6_mouse = "mouse",
    O_6_HANDEDNESS = "handedness",
    O_7_typetest_element = "typetest",
    O_8_clickskills_element = "clickskills",
    O_9_dragskills_element = "dragskills",
    O_41_questionnaire1 = "questionnaire",
    O_14_wordlist = "wordslist",
    O_14_set = "eend2",
    O_42_message = "message",
    O_27_digitspan_element1 = "digitspan",
    O_27_DIGITS_FW_DEMO = "forward-demo",
    O_28_digitspan_element2 = "digitspan",
    O_28_DIGITS_FW = "forward",
    O_29_digitspan_element3 = "digitspan",
    O_29_DIGITS_BW_DEMO = "reverse-demo",
    O_30_DIGITS_BW = "reverse",
    O_43_message = "message",
    O_25_wordlist_element = "wordslist",
    O_44_questionnaire2 = "questionnaire",
    O_45_questionnaire_ntli1 = "questionnaire-ntli",
    O_46_message = "message",
    O_48_questionnaire_current_state3 = "questionnaire-current_state2",
    O_50_message = "message",
    O_50_message_break = "message-break",
    O_34_mouse_element = "mouse",
    O_34_MOUSETYPE = "mousetype"
  )
}

to_utf8 <- function(x) {
  if (is.null(x)) {
    return(x)
  }

  out <- enc2utf8(as.character(x))
  out[is.na(out)] <- NA_character_
  out
}

normalize_pipe_triplets <- function(line) {
  # Expand tokens like "1|question text|0" to "1,question text,0",
  # but keep numeric pipes like "10|12|13|13|13" unchanged.
  gsub(
    "([0-9]+)\\|([^|]*[[:alpha:]][^|]*)\\|([0-9]+)",
    "\\1,\\2,\\3",
    line,
    perl = TRUE
  )
}

read_acs_header <- function(header_path) {
  if (!file.exists(header_path)) {
    stop("Missing header template: ", header_path)
  }

  header_line <- readLines(header_path, n = 1, warn = FALSE, encoding = "UTF-8")
  header_line <- sub("^\ufeff", "", header_line)
  trimws(strsplit(header_line, ",", fixed = TRUE)[[1]])
}

infer_numbered_header_path <- function(raw_file_path, header_dir) {
  raw_name <- basename(raw_file_path)
  suffix <- sub("^acs-nmcb-([0-9]+)\\.csv$", "\\1", raw_name)

  if (identical(suffix, raw_name)) {
    stop("Cannot infer NMCB header suffix from raw file name: ", raw_name)
  }

  file.path(header_dir, paste0("nmcb-acs-header-", suffix, ".csv"))
}

expected_from_general_rules <- function(header_name) {
  if (grepl("_mouse$", header_name, ignore.case = TRUE)) {
    return("mouse")
  }

  if (grepl("_wordlist$", header_name, ignore.case = TRUE)) {
    return("wordslist")
  }

  if (grepl("video_element", header_name, ignore.case = TRUE)) {
    return("video")
  }

  if (grepl("_HANDEDNESS$", header_name, ignore.case = TRUE)) {
    return("handedness")
  }

  if (grepl("_MOUSETYPE$", header_name, ignore.case = TRUE)) {
    return("mousetype")
  }

  if (grepl("typetest_element", header_name, ignore.case = TRUE)) {
    return("typetest")
  }

  if (grepl("clickskills_element", header_name, ignore.case = TRUE)) {
    return("clickskills")
  }

  if (grepl("dragskills_element", header_name, ignore.case = TRUE)) {
    return("dragskills")
  }

  if (grepl("digitspan_element", header_name, ignore.case = TRUE)) {
    return("digitspan")
  }

  if (grepl("_DIGITS_FW_DEMO$", header_name, ignore.case = TRUE)) {
    return("forward-demo")
  }

  if (grepl("_DIGITS_FW$", header_name, ignore.case = TRUE)) {
    return("forward")
  }

  if (grepl("_DIGITS_BW_DEMO$", header_name, ignore.case = TRUE)) {
    return("reverse-demo")
  }

  if (grepl("_DIGITS_BW$", header_name, ignore.case = TRUE)) {
    return("reverse")
  }

  if (grepl("_questionnaire[0-9]+$", header_name, ignore.case = TRUE)) {
    return("questionnaire")
  }

  if (grepl("_questionnaire_ntli[0-9]+$", header_name, ignore.case = TRUE)) {
    return("questionnaire-ntli")
  }

  if (grepl("_message_break$", header_name, ignore.case = TRUE)) {
    return("message-break")
  }

  NA_character_
}

get_expected_checkpoint <- function(header_name, checkpoints) {
  explicit_value <- unname(checkpoints[header_name])[1]
  if (!is.na(explicit_value)) {
    return(explicit_value)
  }

  expected_from_general_rules(header_name)
}

normalize_token <- function(x) {
  tolower(trimws(gsub('^"|"$', "", to_utf8(x))))
}

token_matches <- function(token, expected) {
  normalize_token(token) == normalize_token(unname(expected)[1])
}

build_generalized_misalignment_report <- function(dt, file_name, headers, checkpoints) {
  mismatch_rows <- list()

  for (h in headers) {
    expected_generalized <- expected_from_general_rules(h)
    if (is.na(expected_generalized)) {
      next
    }

    actual_values <- normalize_token(as.character(dt[[h]]))
    expected_norm <- normalize_token(expected_generalized)
    bad_idx <- which(is.na(actual_values) | actual_values != expected_norm)

    if (length(bad_idx) == 0) {
      next
    }

    has_explicit_override <- !is.na(unname(checkpoints[h])[1])
    mismatch_type <- ifelse(is.na(actual_values[bad_idx]), "missing", "value_mismatch")

    mismatch_rows[[length(mismatch_rows) + 1]] <- data.table(
      file = file_name,
      row = bad_idx,
      header = h,
      expected_value = expected_generalized,
      actual_value = as.character(dt[[h]][bad_idx]),
      explicit_checkpoint_exists = has_explicit_override,
      mismatch_type = mismatch_type
    )
  }

  if (length(mismatch_rows) == 0) {
    return(data.table(
      file = character(),
      row = integer(),
      header = character(),
      expected_value = character(),
      actual_value = character(),
      explicit_checkpoint_exists = logical(),
      mismatch_type = character()
    ))
  }

  rbindlist(mismatch_rows, fill = TRUE)
}

align_tokens_to_header <- function(tokens, headers, checkpoints, file_name, row_id) {
  out <- rep(NA_character_, length(headers))
  delete_logs <- list()
  i <- 1
  j <- 1

  split_numbered_token <- function(token_value, headers, start_header_idx, token_idx) {
    header_name <- headers[start_header_idx]
    m <- regexec("^(.*?)([0-9]+)$", header_name)
    parts_match <- regmatches(header_name, m)[[1]]
    if (length(parts_match) != 3) {
      return(NULL)
    }

    base <- parts_match[2]
    start_num <- as.integer(parts_match[3])
    run_headers <- c()
    k <- start_header_idx

    while (k <= length(headers)) {
      expected <- paste0(base, start_num + length(run_headers))
      if (!identical(headers[k], expected)) {
        break
      }
      run_headers <- c(run_headers, headers[k])
      k <- k + 1
    }

    if (length(run_headers) <= 1 || !grepl("|", token_value, fixed = TRUE)) {
      return(NULL)
    }

    token_parts <- trimws(strsplit(token_value, "|", fixed = TRUE)[[1]])
    if (length(token_parts) < length(run_headers)) {
      token_parts <- c(token_parts, rep(NA_character_, length(run_headers) - length(token_parts)))
    }
    if (length(token_parts) > length(run_headers)) {
      token_parts <- c(
        token_parts[seq_len(length(run_headers) - 1)],
        paste(token_parts[length(run_headers):length(token_parts)], collapse = "|")
      )
    }

    list(
      values = token_parts,
      next_header_idx = start_header_idx + length(run_headers),
      next_token_idx = token_idx + 1
    )
  }

  skip_target_for_missing_optional_block <- function(header_name, token_value, headers) {
    if (!header_name %in% c("O_34_mouse_element", "O_34_MOUSETYPE")) {
      return(NA_integer_)
    }

    if (!token_matches(token_value, "video")) {
      return(NA_integer_)
    }

    match("O_35_video5", headers)
  }

  while (i <= length(headers) && j <= length(tokens)) {
    header_name <- headers[i]
    expected <- get_expected_checkpoint(header_name, checkpoints)

    if (!is.na(expected)) {
      if (token_matches(tokens[j], expected)) {
        out[i] <- trimws(tokens[j])
        i <- i + 1
        j <- j + 1
        next
      }

      found_idx <- NA_integer_
      for (k in j:length(tokens)) {
        if (token_matches(tokens[k], expected)) {
          found_idx <- k
          break
        }
      }

      if (!is.na(found_idx)) {
        if (found_idx > j) {
          deleted <- tokens[j:(found_idx - 1)]
        } else {
          deleted <- character(0)
        }
        if (length(deleted) > 0) {
          delete_logs[[length(delete_logs) + 1]] <- data.frame(
            file = file_name,
            row = row_id,
            header = header_name,
            expected_value = expected,
            deleted_count = length(deleted),
            deleted_content = paste(trimws(deleted), collapse = " || "),
            stringsAsFactors = FALSE
          )
        }
        out[i] <- trimws(tokens[found_idx])
        i <- i + 1
        j <- found_idx + 1
        next
      }

      skip_target <- skip_target_for_missing_optional_block(header_name, tokens[j], headers)

      delete_logs[[length(delete_logs) + 1]] <- data.frame(
        file = file_name,
        row = row_id,
        header = header_name,
        expected_value = expected,
        deleted_count = 0,
        deleted_content = NA_character_,
        stringsAsFactors = FALSE
      )

      if (!is.na(skip_target) && skip_target > i) {
        i <- skip_target
        next
      }

      i <- i + 1
      next
    }

    numbered_split <- split_numbered_token(tokens[j], headers, i, j)
    if (!is.null(numbered_split)) {
      out[i:(numbered_split$next_header_idx - 1)] <- numbered_split$values
      i <- numbered_split$next_header_idx
      j <- numbered_split$next_token_idx
      next
    }

    out[i] <- trimws(tokens[j])
    i <- i + 1
    j <- j + 1
  }

  out <- to_utf8(out)
  out[trimws(out) == ""] <- NA_character_

  if (length(delete_logs) == 0) {
    delete_dt <- data.table(
      file = character(),
      row = integer(),
      header = character(),
      expected_value = character(),
      deleted_count = integer(),
      deleted_content = character()
    )
  } else {
    delete_dt <- rbindlist(delete_logs, fill = TRUE)
  }

  list(row = out, delete_log = delete_dt)
}

process_acs_file <- function(raw_file,
                             header_file,
                             output_file,
                             checkpoint_map = default_checkpoint_map()) {
  acs_header <- read_acs_header(header_file)
  lines <- readLines(raw_file, warn = FALSE, encoding = "UTF-8")
  lines <- to_utf8(lines)
  normalized_lines <- to_utf8(vapply(lines, normalize_pipe_triplets, character(1)))
  token_lists <- strsplit(normalized_lines, ",", fixed = TRUE)
  token_lists <- lapply(token_lists, to_utf8)
  original_cols <- vapply(token_lists, length, integer(1))

  aligned <- mapply(
    FUN = function(tok, row_idx) {
      align_tokens_to_header(
        tokens = tok,
        headers = acs_header,
        checkpoints = checkpoint_map,
        file_name = basename(raw_file),
        row_id = row_idx
      )
    },
    tok = token_lists,
    row_idx = seq_along(token_lists),
    SIMPLIFY = FALSE
  )

  aligned_rows <- lapply(aligned, function(x) to_utf8(x$row))
  delete_logs <- rbindlist(lapply(aligned, function(x) x$delete_log), fill = TRUE)

  dt <- as.data.table(do.call(rbind, aligned_rows))
  setnames(dt, acs_header)

  generalized_misalignment_log <- build_generalized_misalignment_report(
    dt = dt,
    file_name = basename(raw_file),
    headers = acs_header,
    checkpoints = checkpoint_map
  )

  output_dir <- dirname(output_file)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  fwrite(dt, output_file, quote = TRUE, na = "")

  list(
    summary = data.table(
      file = basename(raw_file),
      header_template = basename(header_file),
      rows = nrow(dt),
      original_cols_min = min(original_cols),
      original_cols_max = max(original_cols),
      output_cols = ncol(dt),
      checkpoint_deletions = nrow(delete_logs),
      generalized_rule_mismatches = nrow(generalized_misalignment_log),
      exported_to = output_file
    ),
    data = dt,
    delete_log = delete_logs,
    generalized_misalignment_log = generalized_misalignment_log
  )
}

process_acs_batch <- function(raw_dir = "raw",
                              header_dir = "header",
                              export_dir = "export",
                              raw_pattern = "^acs-nmcb-[0-9]+\\.csv$",
                              checkpoint_map = default_checkpoint_map()) {
  if (!dir.exists(export_dir)) {
    dir.create(export_dir, recursive = TRUE)
  }

  raw_files <- list.files(raw_dir, pattern = raw_pattern, full.names = TRUE)

  if (length(raw_files) == 0) {
    stop("No matching CSV files found in raw directory: ", raw_dir)
  }

  results <- lapply(raw_files, function(raw_file) {
    header_file <- infer_numbered_header_path(raw_file, header_dir)
    output_file <- file.path(export_dir, basename(raw_file))

    cat(
      "Processing", basename(raw_file),
      "with", basename(header_file), "\n"
    )

    process_acs_file(
      raw_file = raw_file,
      header_file = header_file,
      output_file = output_file,
      checkpoint_map = checkpoint_map
    )
  })

  processing_summary <- rbindlist(lapply(results, function(x) x$summary), fill = TRUE)
  deleted_cells_log <- rbindlist(lapply(results, function(x) x$delete_log), fill = TRUE)
  generalized_misalignment_log <- rbindlist(
    lapply(results, function(x) x$generalized_misalignment_log),
    fill = TRUE
  )

  deleted_log_path <- file.path(export_dir, "deleted_cells_log.csv")
  generalized_misalignment_log_path <- file.path(export_dir, "generalized_rule_misalignment_log.csv")

  fwrite(deleted_cells_log, deleted_log_path, quote = TRUE, na = "")
  fwrite(generalized_misalignment_log, generalized_misalignment_log_path, quote = TRUE, na = "")

  list(
    summary = processing_summary,
    delete_log = deleted_cells_log,
    generalized_misalignment_log = generalized_misalignment_log,
    deleted_log_path = deleted_log_path,
    generalized_misalignment_log_path = generalized_misalignment_log_path
  )
}
