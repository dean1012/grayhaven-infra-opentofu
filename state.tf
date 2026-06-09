terraform {
  encryption {
    key_provider "pbkdf2" "local" {
      passphrase = local.state_encryption_passphrase
    }

    key_provider "pbkdf2" "previous" {
      passphrase = local.state_encryption_previous_passphrase
    }

    method "aes_gcm" "default" {
      keys = key_provider.pbkdf2.local
    }

    method "aes_gcm" "previous" {
      keys = key_provider.pbkdf2.previous
    }

    state {
      method = method.aes_gcm.default
      fallback {
        method = method.aes_gcm.previous
      }
    }

    plan {
      method = method.aes_gcm.default
      fallback {
        method = method.aes_gcm.previous
      }
    }
  }
}
