# frozen_string_literal: true

require 'json'
require 'logger'
require 'stringio'
require_relative '../lib/AuthenticationSDK/logging/sensitive_logging'

RSpec.describe SensitiveDataFilter do
  let(:filter) { SensitiveDataFilter.new }

  describe '#maskSensitiveDataInJson' do
    it 'masks sensitive fields in a flat JSON object' do
      input = JSON.generate({ 'encryptedRequest' => 'someEncryptedData123', 'foo' => 'bar' })
      parsed = JSON.parse(filter.maskSensitiveDataInJson(input))
      expect(parsed['encryptedRequest']).to eq('X' * 10)
      expect(parsed['foo']).to eq('bar')
    end

    it 'masks both encryptedRequest and encryptedResponse' do
      input = JSON.generate({
                              'encryptedRequest' => 'shortVal',
                              'encryptedResponse' => 'aVeryLongEncryptedValueThatShouldNotRevealLength'
                            })
      parsed = JSON.parse(filter.maskSensitiveDataInJson(input))
      expect(parsed['encryptedRequest']).to eq('X' * 10)
      expect(parsed['encryptedResponse']).to eq('X' * 10)
    end

    it 'masks compound response keys present in post201 models' do
      input = JSON.generate({
                              'accountNumber' => '4111111111111111',
                              'correctedAccountNumber' => '4111111111111111',
                              'hashedNumber' => 'abc123',
                              'expirationDate' => '12/2030',
                              'suffix' => '1111',
                              'prefix' => '411111',
                              'pan' => '4111111111111111',
                              'primaryAccountNumber' => '4111111111111111'
                            })
      parsed = JSON.parse(filter.maskSensitiveDataInJson(input))
      %w[accountNumber correctedAccountNumber hashedNumber expirationDate
         suffix prefix pan primaryAccountNumber].each do |key|
        expect(parsed[key]).to eq('X' * 10), "expected #{key} to be masked, got #{parsed[key].inspect}"
      end
    end

    # Whitespace after the colon must not bypass masking.
    it 'masks values even when JSON contains whitespace after colon' do
      input = '{"cardNumber" :   "4111111111111111", "expirationMonth"  :  12}'
      parsed = JSON.parse(filter.maskSensitiveDataInJson(input))
      expect(parsed['cardNumber']).to eq('X' * 10)
      expect(parsed['expirationMonth']).to eq(9_999)
    end

    # Numeric (non-quoted) values must be masked.
    it 'masks Integer and Float values under sensitive keys' do
      input = JSON.generate({
                              'expirationMonth' => 12,
                              'expirationYear' => 2030,
                              'cvv' => 123,
                              'amount' => 49.95
                            })
      parsed = JSON.parse(filter.maskSensitiveDataInJson(input))
      expect(parsed['expirationMonth']).to eq(9_999)
      expect(parsed['expirationYear']).to eq(9_999)
      expect(parsed['cvv']).to eq(9_999)
      # 'amount' is not in SENSITIVE_KEYS -> passes through unchanged
      expect(parsed['amount']).to eq(49.95)
    end

    # Mixed-case keys must be matched case-insensitively.
    it 'masks mixed-case and snake/kebab-case key variants' do
      input = JSON.generate({
                              'CARDNUMBER' => '4111111111111111',
                              'Card_Number' => '4111111111111111',
                              'card-number' => '4111111111111111',
                              'PaymentInformation' => { 'card' => { 'number' => '4111111111111111' } }
                            })
      parsed = JSON.parse(filter.maskSensitiveDataInJson(input))
      expect(parsed['CARDNUMBER']).to eq('X' * 10)
      expect(parsed['Card_Number']).to eq('X' * 10)
      expect(parsed['card-number']).to eq('X' * 10)
      # PaymentInformation is sensitive but is a Hash -> recurse; inner card.number also masked
      expect(parsed['PaymentInformation']['card']['number']).to eq('X' * 10)
    end

    # Nested Hash under a sensitive key is recursed into; inner sensitive
    # fields are masked individually while non-sensitive structural keys are
    # preserved so the output remains diagnostically useful.
    it 'recurses into a nested Hash under a sensitive key and masks individual sensitive fields' do
      input = JSON.generate({
                              'card' => {
                                'number' => '4111111111111111',
                                'metadata' => { 'note' => 'shipping note' },
                                'unrelatedInner' => 'not-sensitive'
                              }
                            })
      result = JSON.parse(filter.maskSensitiveDataInJson(input))
      expect(result['card']).to be_a(Hash)
      expect(result['card']['number']).to eq('X' * 10)
      expect(result['card']['metadata']).to eq({ 'note' => 'shipping note' })
      expect(result['card']['unrelatedInner']).to eq('not-sensitive')
    end

    # Array values under a sensitive key are recursed into element-by-element.
    it 'recurses into Array values under a sensitive key' do
      input = JSON.generate({ 'token' => ['t1', 't2', { 'inner' => 'keep', 'cvv' => '123' }] })
      result = JSON.parse(filter.maskSensitiveDataInJson(input))
      expect(result['token']).to be_a(Array)
      # Scalar strings inside a Hash-walked array do NOT get masked by key (no key),
      # but Hash elements have their own sensitive inner fields masked.
      expect(result['token'][2]['cvv']).to eq('X' * 10)
      expect(result['token'][2]['inner']).to eq('keep')
    end

    # An array of objects with sensitive fields gets each element masked.
    it 'recursively masks sensitive fields inside arrays of objects' do
      input = JSON.generate({
                              'lineItems' => [
                                { 'productSku' => 'A', 'cvv' => '111' },
                                { 'productSku' => 'B', 'cvv' => '222' }
                              ]
                            })
      result = JSON.parse(filter.maskSensitiveDataInJson(input))
      expect(result['lineItems'][0]['cvv']).to eq('X' * 10)
      expect(result['lineItems'][1]['cvv']).to eq('X' * 10)
      expect(result['lineItems'][0]['productSku']).to eq('A')
      expect(result['lineItems'][1]['productSku']).to eq('B')
    end

    it 'recursively masks sensitive fields under non-sensitive parents' do
      input = JSON.generate({ 'orderInformation' => { 'billTo' => { 'email' => 'a@b.com' } } })
      raw = filter.maskSensitiveDataInJson(input)
      # billTo is sensitive Hash -> recurse; inner email key matches and is masked
      expect(JSON.parse(raw)['orderInformation']['billTo']['email']).to eq('X' * 10)
      expect(raw).not_to include('a@b.com')
    end

    it 'produces fixed-length mask regardless of input length' do
      short = JSON.parse(filter.maskSensitiveDataInJson(JSON.generate({ 'encryptedRequest' => 'abc' })))
      long  = JSON.parse(filter.maskSensitiveDataInJson(JSON.generate({ 'encryptedRequest' => 'a' * 500 })))
      expect(short['encryptedRequest']).to eq(long['encryptedRequest'])
      expect(short['encryptedRequest'].length).to eq(10)
    end

    it 'fails closed on invalid JSON (non-JSON / partial / wrapped input)' do
      expect(filter.maskSensitiveDataInJson('Response Body: this is not JSON at all'))
        .to eq(SensitiveDataFilter::REDACTED_PAYLOAD)
      expect(filter.maskSensitiveDataInJson('{ "partial": "tru'))
        .to eq(SensitiveDataFilter::REDACTED_PAYLOAD)
      expect(filter.maskSensitiveDataInJson('')).to eq(SensitiveDataFilter::REDACTED_PAYLOAD)
      expect(filter.maskSensitiveDataInJson(nil)).to eq(SensitiveDataFilter::REDACTED_PAYLOAD)
    end

    it 'fails closed when parsed value is a bare scalar rather than an object' do
      expect(filter.maskSensitiveDataInJson('"just a string"'))
        .to eq(SensitiveDataFilter::REDACTED_PAYLOAD)
      expect(filter.maskSensitiveDataInJson('1234'))
        .to eq(SensitiveDataFilter::REDACTED_PAYLOAD)
    end
  end

  describe '#call (formatter pipeline)' do
    let(:time) { Time.now }

    it 'masks sensitive data inside a "label: {json}" message' do
      payload = JSON.generate({ 'cardNumber' => '4111111111111111' })
      out = filter.call('DEBUG', time, 'Test', "Response Body: #{payload}")
      expect(out).not_to include('4111111111111111')
      expect(out).to include('XXXXXXXXXX')
    end

    # Defense-in-depth masking when JSON is wrapped
    # with a textual prefix AND a textual suffix (no clean label: split).
    it 'extracts and masks an embedded JSON object surrounded by free text' do
      payload = JSON.generate({ 'cardNumber' => '4111111111111111', 'cvv' => 123 })
      out = filter.call('DEBUG', time, 'Test',
                        "Received response from API #{payload} (latency=42ms)")
      expect(out).not_to include('4111111111111111')
      expect(out).not_to include('"cvv":123')
      expect(out).to include('XXXXXXXXXX')
      expect(out).to include('latency=42ms')
    end

    it 'masks multiple embedded JSON objects in the same message' do
      a = JSON.generate({ 'cardNumber' => '4111111111111111' })
      b = JSON.generate({ 'token' => 'secret-token-value' })
      out = filter.call('DEBUG', time, 'Test', "first=#{a} second=#{b} done")
      expect(out).not_to include('4111111111111111')
      expect(out).not_to include('secret-token-value')
      expect(out).to include('first=')
      expect(out).to include('second=')
      expect(out).to include('done')
    end

    it 'redacts a message containing partial / unparseable JSON-looking content' do
      out = filter.call('DEBUG', time, 'Test', '{ "cardNumber": "4111111111111111')
      expect(out).not_to include('4111111111111111')
      expect(out).to include(SensitiveDataFilter::REDACTED_PAYLOAD)
    end

    it 'passes through plain text messages without JSON markers' do
      out = filter.call('INFO', time, 'Test', 'Encrypting request payload')
      expect(out).to include('Encrypting request payload')
    end

    it 'does not throw NoMethodError for the removed maskSensitiveString API' do
      expect(filter).not_to respond_to(:maskSensitiveString)
    end
  end

  # Negative test: assert MLEUtility decrypt sinks are gated and masked.
  describe 'MLEUtility decrypted-response log sinks' do
    let(:mle_source) do
      File.read(File.expand_path('../lib/AuthenticationSDK/util/MLEUtility.rb', __dir__))
    end

    it 'gates any decrypted-response interpolation behind an explicit opt-in toggle' do
      expect(mle_source).to include('mle_plaintext_logging_enabled?')
      expect(mle_source).to include('enable_mle_plaintext_logging!')
      # Any logger call that interpolates decryptedResponse must also route it through the masking formatter.
      mle_source.scan(/logger\.\w+\([^)]*#\{[^}]*decryptedResponse[^}]*\}[^)]*\)/).each do |sink|
        expect(sink).to include('maskSensitiveDataInJson'), "unmasked decrypted sink: #{sink}"
      end
    end

    it 'does not log decrypted response at INFO or higher severity' do
      expect(mle_source).not_to match(/logger\.(info|warn|error|fatal)\([^)]*decryptedResponse/)
    end

    it 'when routed through the formatter, decrypted plaintext is never present at DEBUG' do
      io = StringIO.new
      logger = Logger.new(io)
      logger.level = Logger::DEBUG
      logger.formatter = SensitiveDataFilter.new

      # Simulate the gated debug emit the way MLEUtility now does it: mask first, then interpolate.
      formatter = SensitiveDataFilter.new
      decrypted = JSON.generate({ 'cardNumber' => '4111111111111111', 'cvv' => '123' })
      logger.debug("LOG_NETWORK_RESPONSE_AFTER_MLE_DECRYPTION: #{formatter.maskSensitiveDataInJson(decrypted)}")

      expect(io.string).not_to include('4111111111111111')
      expect(io.string).not_to include('"cvv":"123"')
      expect(io.string).to include('XXXXXXXXXX')
    end
  end
end
