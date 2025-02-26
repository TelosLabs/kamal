class Kamal::Secrets::Adapters::Dashlane < Kamal::Secrets::Adapters::Base
  private
    def login(account)
      unless loggedin?(account)
        `echo #{account.shellescape} | dcli accounts whoami`
        raise RuntimeError, "Failed to login to Dashlane" unless $?.success?
      end
    end

    def loggedin?(account)
      `(echo #{account.shellescape}; cat) | dcli accounts whoami`.strip == account && $?.success?
    end

    def fetch_secrets(secrets, from:, account:, session:)
      pp "fetching secrets"
      secrets = prefixed_secrets(secrets, from: from)
      items = `dcli secret #{secrets.map(&:shellescape).join(" ")} -o json`
      raise RuntimeError, "Failed to fetch secrets from Dashlane" unless $?.success?

      begin
        items = JSON.parse(items)
      rescue JSON::ParserError
        raise RuntimeError, "Invalid JSON response from Dashlane CLI"
      end

      {}.tap do |results|
        items.each do |item|
          results[item["title"]] = item["content"]
        end

        if (missing_items = secrets - results.keys).any?
          raise RuntimeError, "Could not find the following items in Dashlane: #{missing_items.join(", ")}"
        end
      end
    end

    def check_dependencies!
      raise RuntimeError, "Dashlane CLI is not installed" unless cli_installed?
    end

    def cli_installed?
      `dcli --version 2> /dev/null`
      $?.success?
    end
end
