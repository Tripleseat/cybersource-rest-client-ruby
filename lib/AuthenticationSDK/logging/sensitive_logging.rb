require 'logger'
require 'json'

class SensitiveDataFilter < Logger::Formatter
    SENSITIVE_KEYS = %w[
        securitycode number cardnumber expirationmonth expirationyear expiration
        expirationdate account routingnumber email firstname lastname phonenumber
        type token signature prefix suffix bin pan encryptedrequest encryptedresponse
        password secret apikey accesstoken refreshtoken ssn creditcard debitcard cvv pin
        cardholder nameoncard holdername track1 track2 trackdata
        iban swift bic dateofbirth birthdate taxid
        privatekey publickey authorization bearer
        cavv xid pares micr jwt jwe
        paymentinformation paymentinstrument card billto shipto
        customer driverlicense
    ].freeze

    REDACTED_PAYLOAD = '[REDACTED]'.freeze
    REDACTED_VALUE = ('X' * 10).freeze

    def json_object?(str)
        parsed = JSON.parse(str)
        parsed.is_a?(Hash)
    rescue JSON::ParserError, TypeError
        false
    end

    def maskSensitiveDataInJson(input)
        str = input.to_s
        parsed =
            begin
                JSON.parse(str)
            rescue JSON::ParserError
                # Fall back to Ruby Hash#inspect syntax (e.g. interpolated
                # "#{hash}" in a log string produces {"k"=>"v"} or {:k=>"v"}).
                # Convert heuristically to JSON without eval, then retry.
                converted = rubyInspectToJson(str)
                converted.nil? ? (raise) : JSON.parse(converted)
            end
        unless parsed.is_a?(Hash) || parsed.is_a?(Array)
            return REDACTED_PAYLOAD
        end
        masked_data = maskJsonObject(parsed)
        JSON.generate(masked_data)
    rescue JSON::ParserError, TypeError, EncodingError
        REDACTED_PAYLOAD
    end

    # Best-effort, eval-free conversion of Ruby Hash/Array#inspect output to
    # JSON. Returns nil if the input cannot plausibly be Ruby inspect syntax
    # (so the caller can fail closed). Handles:
    #   :symbol => "v"     -> "symbol": "v"   (legacy inspect)
    #   "k" => "v"         -> "k": "v"        (string-key inspect)
    #   { bareword: "v" }  -> { "bareword": "v" }  (Ruby 3.4+ shorthand)
    #   bare nil tokens    -> null
    # Does NOT attempt to handle every Ruby literal (Procs, Time, custom
    # #inspect, etc.); anything unrecognized will cause JSON.parse to fail
    # downstream and the span will be redacted.
    def rubyInspectToJson(str)
        out = +''
        i = 0
        len = str.length
        in_string = false
        escape = false

        while i < len
            ch = str[i]
            if in_string
                out << ch
                if escape
                    escape = false
                elsif ch == '\\'
                    escape = true
                elsif ch == '"'
                    in_string = false
                end
                i += 1
                next
            end

            if ch == '"'
                in_string = true
                out << ch
                i += 1
                next
            end

            # :symbol_key (legacy inspect): preceded by { , [ or whitespace
            if ch == ':' && i + 1 < len && str[i + 1] =~ /[A-Za-z_]/ &&
               (out.empty? || out[-1] =~ /[\{\[,\s]/)
                j = i + 1
                j += 1 while j < len && str[j] =~ /[A-Za-z0-9_]/
                sym = str[(i + 1)...j]
                out << '"' << sym << '"'
                i = j
                next
            end

            # bareword: shorthand (Ruby 3.4+ inspect): preceded by { , or
            # whitespace; followed by ':' then whitespace (so we don't
            # confuse with the '::' constant-resolution operator).
            if ch =~ /[A-Za-z_]/ &&
               (out.empty? || out[-1] =~ /[\{\[,\s]/)
                j = i
                j += 1 while j < len && str[j] =~ /[A-Za-z0-9_]/
                if j < len && str[j] == ':' && str[j + 1] != ':' &&
                   (j + 1 >= len || str[j + 1] =~ /\s/)
                    word = str[i...j]
                    out << '"' << word << '":'
                    i = j + 1
                    next
                end
            end

            # => operator
            if ch == '=' && str[i + 1] == '>'
                out << ':'
                i += 2
                next
            end

            # bare nil -> null
            if ch == 'n' && str[i, 3] == 'nil' &&
               (i.zero? || str[i - 1] =~ /[\s,\{\[:]/) &&
               (i + 3 >= len || str[i + 3] =~ /[\s,\}\]]/)
                out << 'null'
                i += 3
                next
            end

            out << ch
            i += 1
        end

        out
    end

    def maskJsonObject(obj)
        case obj
        when Hash
            obj.each_with_object({}) do |(key, value), result|
                result[key] = if isSensitiveKey?(key)
                              maskSensitiveValue(value)
                            else
                              maskJsonObject(value)
                            end
            end
        when Array
            obj.map { |item| maskJsonObject(item) }
        else
            obj
        end
    end

    def isSensitiveKey?(key)
        normalized = key.to_s.downcase.gsub(/[^a-z0-9]/, '')
        SENSITIVE_KEYS.any? { |sensitive| normalized.include?(sensitive) }
    end

    # When a sensitive key wraps a value, redact scalars directly. For nested
    # Hash/Array containers, recurse via maskJsonObject so individual inner
    # values are masked based on their own key names rather than blanket-
    # redacting the entire container.
    def maskSensitiveValue(value)
        case value
        when Hash, Array
            maskJsonObject(value)
        when String
            REDACTED_VALUE
        when Integer, Float
            9_999
        when TrueClass, FalseClass
            false
        else
            value
        end
    end

    def maskValue(value)
        maskSensitiveValue(value)
    end

    # Central defense-in-depth entry point. Regardless of how the log message
    # is shaped (Ruby Hash/Array, pure JSON string, "label: {json}",
    # "prefix {json} suffix", or even multiple embedded JSON blobs), every
    # JSON Object/Array substring is extracted, parsed, and masked in-place.
    # Any JSON-shaped substring that fails to parse is replaced with
    # REDACTED_PAYLOAD (fail-closed) so a partially-decrypted or truncated
    # body cannot leak through the wrapper.
    def call(severity, time, progname, msg)
        maskedMessage =
            case msg
            when Hash, Array
                # Ruby Hash/Array passed directly to logger.<level>(obj). Walk
                # the structure with maskJsonObject so individual sensitive
                # fields are masked; Hash#to_s produces "key=>value" syntax
                # which is NOT valid JSON, so we must not route it through
                # the string-based parser path.
                JSON.generate(maskJsonObject(msg))
            else
                msg_str = msg.to_s
                begin
                    JSON.parse(msg_str)
                    maskSensitiveDataInJson(msg_str)
                rescue JSON::ParserError, TypeError
                    maskEmbeddedJson(msg_str)
                end
            end
        formatLogEntry(severity, time, progname, maskedMessage)
    end

    # Walk the string, extract every top-level balanced {...} or [...] span
    # (respecting JSON string/escape rules), and mask each in place. If no
    # JSON-shaped span is present, the original text is returned unchanged.
    # If a span is found but cannot be parsed, the entire message is redacted.
    def maskEmbeddedJson(msg_str)
        return msg_str unless msg_str.include?('{') || msg_str.include?('[')

        result = +''
        i = 0
        len = msg_str.length
        found_any = false

        while i < len
            ch = msg_str[i]
            if ch == '{' || ch == '['
                span_end = find_balanced_json_end(msg_str, i)
                if span_end.nil?
                    # Unbalanced JSON-looking content remaining: fail closed.
                    return REDACTED_PAYLOAD
                end
                candidate = msg_str[i..span_end]
                masked = maskSensitiveDataInJson(candidate)
                # maskSensitiveDataInJson returns REDACTED_PAYLOAD on parse failure,
                # which is the safe outcome we want to propagate.
                result << masked
                i = span_end + 1
                found_any = true
            else
                result << ch
                i += 1
            end
        end

        found_any ? result : msg_str
    end

    # Returns the index of the matching closing brace/bracket for the JSON
    # span beginning at start_idx, honoring JSON string and escape rules.
    # Returns nil if unbalanced.
    def find_balanced_json_end(str, start_idx)
        depth = 0
        in_string = false
        escape = false
        i = start_idx
        len = str.length

        while i < len
            ch = str[i]
            if in_string
                if escape
                    escape = false
                elsif ch == '\\'
                    escape = true
                elsif ch == '"'
                    in_string = false
                end
            else
                case ch
                when '"'
                    in_string = true
                when '{', '['
                    depth += 1
                when '}', ']'
                    depth -= 1
                    return i if depth.zero?
                    return nil if depth < 0
                end
            end
            i += 1
        end
        nil
    end

    def formatLogEntry(severity, _time, progname, msg)
        datetime = DateTime.now
        date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
        "[#{date_format}] #{severity.ljust(10)} (#{progname}): #{msg}\n"
    end
end
