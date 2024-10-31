class Kamal::Secrets::Adapters::Dashlane < Kamal::Secrets::Adapters::Base
  private

  def login(_account)
    `dcli sync`
    raise "Failed to login to Dashlane" unless $?.success?
  end

  def fetch_secrets(secrets, account:, session:)
    items = `dcli secret #{secrets.map(&:shellescape).join(" ")} -o json`
    raise "Could not read #{secrets} from Dashlane" unless $?.success?

    items = JSON.parse(items)

    {}.tap do |results|
      items.each do |item|
        results[item["title"]] = item["content"]
      end

      if (missing_items = secrets - results.keys).any?
        raise "Could not find #{missing_items.join(", ")} in Dashlane"
      end
    end
  end

  def check_dependencies!
    raise "Dashlane CLI is not installed" unless cli_installed?
  end

  def cli_installed?
    `dcli --version 2> /dev/null`
    $?.success?
  end
end
