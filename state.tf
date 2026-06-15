terraform {
  encryption {
    # Historical state used OpenTofu's derived PBKDF2 metadata key. The current
    # key writes a managed alias while the previous-key fallback reads the
    # legacy metadata key during passphrase rotation.
    key_provider "pbkdf2" "local" {
      passphrase               = local.state_encryption_passphrase
      encrypted_metadata_alias = "grayhaven_state_v1"
    }

    key_provider "pbkdf2" "previous" {
      passphrase               = local.state_encryption_previous_passphrase
      encrypted_metadata_alias = "key_provider.pbkdf2.local"
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
