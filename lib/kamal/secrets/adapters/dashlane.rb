class Kamal::Secrets::Adapters::Dashlane < Kamal::Secrets::Adapters::Base
  def requires_account?
    false
  end

  private
    def login(account)
      system('dcli sync', out: $stderr)

      raise RuntimeError, "Failed to login to Dashlane" unless $?.success?
    end

    def fetch_secrets(secrets, from:, account:, session:)
      secrets = secrets.map { uri(it) }.map(&:shellescape)

      # TODO: Collect failed fetches and show a single error with all not found items.
      # TODO: Handle parsing fields. `dcli read 'dl://gorails.com/password'`

      items = secrets.map do |secret|
        json = `dcli read #{secret}`

        raise RuntimeError, "Failed to fetch secret \"${secret}\" from Dashlane" unless $?.success?

        begin
          JSON.parse(json)
        rescue JSON::ParserError
          raise RuntimeError, "Invalid JSON response from Dashlane CLI"
        end
      end

      # TODO: Make it work with secrets (doesn't have password)
      {}.tap do |results|
        items.each do |item|
          results[item["title"]] = item["password"]
        end
      end
    end

    def uri(secret) = "dl://#{secret}"

    def check_dependencies!
      raise RuntimeError, "Dashlane CLI is not installed" unless cli_installed?
    end

    def cli_installed?
      system('dcli --version', out: File::NULL)
      $?.success?
    end
end
