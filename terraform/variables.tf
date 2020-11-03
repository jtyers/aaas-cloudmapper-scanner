locals {
  lambda_timeout = 300 # timeout for scanner

  # initial delay for scanner - this is to ensure simultaneous scans of the same
  # account in the same region do not trigger AWS API request rate limits
  scanner_delay_seconds = 5
}

variable scanner_function_zip {
  type = string
}

variable scanner_invoker_function_zip {
  type = string
}

variable ssh_public_key_file {
  type = string
}
