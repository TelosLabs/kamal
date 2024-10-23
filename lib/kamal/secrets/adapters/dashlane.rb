class Kamal::Secrets::Adapters::Dashlane < Kamal::Secrets::Adapters::Base
  private
    def login(account)
      unless loggedin?(account)
        `dcli sync`
        raise RuntimeError, "Failed to login to Dashlane" unless $?.success?
      end
    end

    def loggedin?(account)
      `dcli accounts whoami`.strip == account
    end

    def fetch_secrets(secrets, account:, session:)
      items = `dcli secret #{secrets.map(&:shellescape).join(" ")} -o json`
      raise RuntimeError, "Could not read #{secrets} from Dashlane" unless $?.success?

      items = JSON.parse(items)

      {}.tap do |results|
        items.each do |item|
          results[item["title"]] = item["content"]
        end

        if (missing_items = secrets - results.keys).any?
          raise RuntimeError, "Could not find #{missing_items.join(", ")} in Dashlane"
        end
      end
    end
end
