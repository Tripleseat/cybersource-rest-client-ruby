# frozen_string_literal: true

require 'jose'
require 'json'
require 'base64'
require 'openssl'
require_relative '../lib/AuthenticationSDK/util/AuthJWEUtility'
require_relative '../lib/AuthenticationSDK/util/Constants'

RSpec.describe AuthJWEUtility do
  let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:jwk) { JOSE::JWK.from_key(rsa_key) }
  let(:plaintext) { '{"test": "data"}' }

  # Helper: build a compact JWE with specific header algorithms using the JOSE library
  def build_jwe(jwk, plaintext, alg, enc)
    header = { 'alg' => alg, 'enc' => enc }
    JOSE::JWE.block_encrypt(jwk, plaintext, header).compact
  end

  # Helper: build a fake compact JWE string with an arbitrary header (5 dot-separated parts)
  def build_fake_jwe_with_header(header_hash)
    header_json = JSON.generate(header_hash)
    encoded_header = Base64.urlsafe_encode64(header_json, padding: false)
    # Use dummy segments for the remaining 4 parts
    "#{encoded_header}.AAAA.BBBB.CCCC.DDDD"
  end

  describe '.decrypt_jwe_using_private_key' do
    context 'with allowed algorithm RSA-OAEP-256 + A256GCM' do
      it 'decrypts successfully' do
        jwe = build_jwe(jwk, plaintext, 'RSA-OAEP-256', 'A256GCM')
        result = AuthJWEUtility.decrypt_jwe_using_private_key(jwk, jwe)
        expect(result).to eq(plaintext)
      end
    end

    context 'with allowed algorithm RSA-OAEP + A256GCM' do
      it 'decrypts successfully' do
        jwe = build_jwe(jwk, plaintext, 'RSA-OAEP', 'A256GCM')
        result = AuthJWEUtility.decrypt_jwe_using_private_key(jwk, jwe)
        expect(result).to eq(plaintext)
      end
    end

    context 'with allowed algorithm RSA-OAEP-256 + A128GCM' do
      it 'decrypts successfully' do
        jwe = build_jwe(jwk, plaintext, 'RSA-OAEP-256', 'A128GCM')
        result = AuthJWEUtility.decrypt_jwe_using_private_key(jwk, jwe)
        expect(result).to eq(plaintext)
      end
    end

    context 'with allowed algorithm RSA-OAEP + A128GCM' do
      it 'decrypts successfully' do
        jwe = build_jwe(jwk, plaintext, 'RSA-OAEP', 'A128GCM')
        result = AuthJWEUtility.decrypt_jwe_using_private_key(jwk, jwe)
        expect(result).to eq(plaintext)
      end
    end

    context 'with disallowed key encryption algorithm RSA1_5' do
      it 'raises an error before attempting decryption' do
        jwe = build_fake_jwe_with_header({ 'alg' => 'RSA1_5', 'enc' => 'A256GCM' })
        expect do
          AuthJWEUtility.decrypt_jwe_using_private_key(jwk, jwe)
        end.to raise_error(StandardError, /Unsupported JWE key encryption algorithm 'RSA1_5'/)
      end
    end

    context 'with disallowed key encryption algorithm dir' do
      it 'raises an error before attempting decryption' do
        jwe = build_fake_jwe_with_header({ 'alg' => 'dir', 'enc' => 'A256GCM' })
        expect do
          AuthJWEUtility.decrypt_jwe_using_private_key(jwk, jwe)
        end.to raise_error(StandardError, /Unsupported JWE key encryption algorithm 'dir'/)
      end
    end

    context 'with disallowed key encryption algorithm A128KW' do
      it 'raises an error before attempting decryption' do
        jwe = build_fake_jwe_with_header({ 'alg' => 'A128KW', 'enc' => 'A256GCM' })
        expect do
          AuthJWEUtility.decrypt_jwe_using_private_key(jwk, jwe)
        end.to raise_error(StandardError, /Unsupported JWE key encryption algorithm 'A128KW'/)
      end
    end

    context 'with disallowed content encryption algorithm A128CBC-HS256' do
      it 'raises an error before attempting decryption' do
        jwe = build_fake_jwe_with_header({ 'alg' => 'RSA-OAEP-256', 'enc' => 'A128CBC-HS256' })
        expect do
          AuthJWEUtility.decrypt_jwe_using_private_key(jwk, jwe)
        end.to raise_error(StandardError, /Unsupported JWE content encryption algorithm 'A128CBC-HS256'/)
      end
    end

    context 'with missing alg header' do
      it 'raises an error' do
        jwe = build_fake_jwe_with_header({ 'enc' => 'A256GCM' })
        expect do
          AuthJWEUtility.decrypt_jwe_using_private_key(jwk, jwe)
        end.to raise_error(StandardError, /Unsupported JWE key encryption algorithm/)
      end
    end

    context 'with missing enc header' do
      it 'raises an error' do
        jwe = build_fake_jwe_with_header({ 'alg' => 'RSA-OAEP-256' })
        expect do
          AuthJWEUtility.decrypt_jwe_using_private_key(jwk, jwe)
        end.to raise_error(StandardError, /Unsupported JWE content encryption algorithm/)
      end
    end

    context 'with nil encoded_response' do
      it 'raises an error' do
        expect do
          AuthJWEUtility.decrypt_jwe_using_private_key(jwk, nil)
        end.to raise_error(StandardError, /nil or empty/)
      end
    end

    context 'with empty encoded_response' do
      it 'raises an error' do
        expect do
          AuthJWEUtility.decrypt_jwe_using_private_key(jwk, '')
        end.to raise_error(StandardError, /nil or empty/)
      end
    end

    context 'with invalid JWE format (wrong number of parts)' do
      it 'raises an error' do
        expect do
          AuthJWEUtility.decrypt_jwe_using_private_key(jwk, 'only.three.parts')
        end.to raise_error(StandardError, /Invalid JWE compact serialization/)
      end
    end

    context 'with invalid JSON in JWE header' do
      it 'raises a descriptive error about JSON parsing failure' do
        # Build a JWE with 5 parts but the header is not valid JSON
        invalid_header = Base64.urlsafe_encode64('this is not json', padding: false)
        fake_jwe = "#{invalid_header}.AAAA.BBBB.CCCC.DDDD"
        expect do
          AuthJWEUtility.decrypt_jwe_using_private_key(jwk, fake_jwe)
        end.to raise_error(StandardError, /Invalid JWE header: failed to parse JSON/)
      end
    end

    context 'with corrupted base64 in JWE header that decodes to invalid JSON' do
      it 'raises a descriptive error' do
        # Encode something that looks like JSON but is malformed
        broken_json = Base64.urlsafe_encode64('{"alg": broken}', padding: false)
        fake_jwe = "#{broken_json}.AAAA.BBBB.CCCC.DDDD"
        expect do
          AuthJWEUtility.decrypt_jwe_using_private_key(jwk, fake_jwe)
        end.to raise_error(StandardError, /Invalid JWE header: failed to parse JSON/)
      end
    end
  end
end
