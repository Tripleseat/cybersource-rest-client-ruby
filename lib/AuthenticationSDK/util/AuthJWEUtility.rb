# frozen_string_literal: true

require_relative './Cache'
require_relative './Constants'
require 'stringio'
require 'jose'
require 'json'
require 'base64'

public

class AuthJWEUtility
  # <b>DEPRECATED:</b> This method has been marked as Deprecated and will be removed in coming releases. Use <tt>decrypt_jwe_using_private_key()</tt> instead.
  def self.decrypt_jwe_using_pem(merchant_config, encoded_response)
    warn('[DEPRECATED] `decrypt_jwe_using_pem()` method is deprecated and will be removed in coming releases. Use `decrypt_jwe_using_private_key()` instead.')
    validate_jwe_algorithms(encoded_response)
    key = Cache.new.fetchPEMFileForNetworkTokenization(merchant_config.pemFileDirectory)
    JOSE::JWE.block_decrypt(key, encoded_response).first
  end

  def self.decrypt_jwe_using_private_key(private_key, encoded_response)
    validate_jwe_algorithms(encoded_response)
    JOSE::JWE.block_decrypt(private_key, encoded_response).first
  end

  # Validates the JWE header algorithms before decryption to prevent algorithm
  # substitution attacks (e.g., Bleichenbacher padding oracle via RSA1_5,
  # or chosen-plaintext via 'dir').
  #
  # Only algorithms supported by CGK are permitted:
  #   alg: RSA-OAEP, RSA-OAEP-256
  #   enc: A128GCM, A256GCM
  def self.validate_jwe_algorithms(encoded_response)
    if encoded_response.nil? || encoded_response.to_s.strip.empty?
      raise StandardError, 'Encoded JWE response is nil or empty'
    end

    parts = encoded_response.to_s.split('.')
    unless parts.length == 5
      raise StandardError, "Invalid JWE compact serialization: expected 5 parts, got #{parts.length}"
    end

    # Base64url-decode the JOSE header (first segment); add padding as needed
    header_b64 = parts[0]
    # Add padding if needed for proper base64url decoding
    header_b64 += '=' * (4 - header_b64.length % 4) if header_b64.length % 4 != 0
    header_json = Base64.urlsafe_decode64(header_b64)
    begin
      header = JSON.parse(header_json)
    rescue JSON::ParserError => e
      raise StandardError, "Invalid JWE header: failed to parse JSON - #{e.message}"
    end

    alg = header['alg']
    enc = header['enc']

    unless Constants::ALLOWED_JWE_KEY_ENCRYPTION_ALGORITHMS.include?(alg)
      raise StandardError, "Unsupported JWE key encryption algorithm '#{alg}'. " \
        "Allowed: #{Constants::ALLOWED_JWE_KEY_ENCRYPTION_ALGORITHMS.join(', ')}"
    end

    unless Constants::ALLOWED_JWE_CONTENT_ENCRYPTION_ALGORITHMS.include?(enc)
      raise StandardError, "Unsupported JWE content encryption algorithm '#{enc}'. " \
        "Allowed: #{Constants::ALLOWED_JWE_CONTENT_ENCRYPTION_ALGORITHMS.join(', ')}"
    end
  end

  private_class_method :validate_jwe_algorithms
end
