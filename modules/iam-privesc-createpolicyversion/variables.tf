variable "lab_prefix" {
  description = "Prefix for all lab resources"
  type        = string
}

variable "flag_value" {
  description = "The flag value to be stored in the IAM role tag"
  type        = string
  sensitive   = true
}
