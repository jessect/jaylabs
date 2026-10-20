variable "project_id" {
  description = "Any ID works: the emulators accept every project."
  type        = string
  default     = "jaylabs-local"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "prefix" {
  type    = string
  default = "jaylabs-lab003"
}

variable "endpoints" {
  description = "REST endpoints of the local emulators (must end with /)."
  type = object({
    storage   = string
    pubsub    = string
    firestore = string
    spanner   = string
  })
  default = {
    storage   = "http://localhost:4443/storage/v1/" # fake-gcs-server
    pubsub    = "http://localhost:8085/v1/"         # Pub/Sub emulator
    firestore = "http://localhost:8080/v1/"         # Firestore emulator
    spanner   = "http://localhost:9020/v1/"         # Spanner emulator (REST port)
  }
}
