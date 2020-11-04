locals {
  lambda_timeout = 1800 # timeout for scanner - 30mins

  # initial delay for scanner - this is to ensure simultaneous scans of the same
  # account in the same region do not trigger AWS API request rate limits
  scanner_delay_seconds = 5
}

variable scanner_function_tgz {
  type = string
}

variable scanner_invoker_function_zip {
  type = string
}
