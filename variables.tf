variable "namespace" {
  description = <<EOH
The namespace to create the virtual training lab. This should describe the
training and must be unique to all current trainings. IAM users, workstations,
and resources will be scoped under this namespace.
It is best if you add this to your .tfvars file so you do not need to type
it manually with each run
EOH
}