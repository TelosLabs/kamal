require "test_helper"

class DashlaneAdapterTest < SecretAdapterTestCase
  setup do
    `true` # Ensure $? is 0
  end

  test "fetch without CLI installed" do
    stub_ticks_with("dcli -v", succeed: false)

    error = assert_raises RuntimeError do
      JSON.parse(shellunescape(run_command("fetch", "SECRET1")))
    end
    assert_equal "Dashlane CLI is not installed", error.message
  end

  test "fetch" do
    stub_ticks.with("dcli sync").returns("email@example.com")

    stub_ticks
      .with("dcli secret SECRET1 SECRET2 SECRET3 -o json")
      .returns(<<~JSON)
        [
          {
            "id": "1234567891234567891",
            "title": "SECRET1",
            "content": "secret1",
            "creationDatetime": "1724926635",
            "lastBackupTime": "1724926635",
            "lastUse": "1724926635",
            "localeFormat": "UNIVERSAL",
            "spaceId": "123456",
            "userModificationDatetime": "1724926635",
            "secured": "false"
          },
          {
            "id": "1234567891234567891",
            "title": "SECRET2",
            "content": "secret2",
            "creationDatetime": "1724926084",
            "lastBackupTime": "1724926635",
            "lastUse": "123456789",
            "localeFormat": "UNIVERSAL",
            "spaceId": "123456",
            "userModificationDatetime": "123456789",
            "secured": "false"
          },
          {
            "id": "1234567891234567891",
            "title": "SECRET3",
            "content": "secret3",
            "creationDatetime": "1724926084",
            "lastBackupTime": "1724926635",
            "lastUse": "123456789",
            "localeFormat": "UNIVERSAL",
            "spaceId": "123456",
            "userModificationDatetime": "123456789",
            "secured": "false"
          }
        ]
      JSON

    json = JSON.parse(shellunescape(run_command("fetch", "SECRET1", "SECRET2", "SECRET3")))

    expected_json = {
      "SECRET1" => "secret1",
      "SECRET2" => "secret2",
      "SECRET3" => "secret3"
    }

    assert_equal expected_json, json
  end

  test "fetch with from" do
    stub_ticks.with("dcli sync").returns("email@example.com")

    stub_ticks
      .with("dcli secret SECRET1 APP/SECRET1 -o json")
      .returns(<<~JSON)
        [
          {
            "id": "1234567891234567891",
            "title": "SECRET1",
            "content": "secret1",
            "creationDatetime": "1724926084",
            "lastBackupTime": "1724926635",
            "lastUse": "123456789",
            "localeFormat": "UNIVERSAL",
            "spaceId": "123456",
            "userModificationDatetime": "123456789",
            "secured": "false"
          },
          {
            "id": "1234567891234567891",
            "title": "APP/SECRET2",
            "content": "secret2",
            "creationDatetime": "1724926084",
            "lastBackupTime": "1724926635",
            "lastUse": "123456789",
            "localeFormat": "UNIVERSAL",
            "spaceId": "123456",
            "userModificationDatetime": "123456789",
            "secured": "false"
          }
        ]
      JSON

    json = JSON.parse(shellunescape(run_command("fetch", "--from", "SECRET1", "APP/SECRET2")))

    expected_json = {
      "SECRET1" => "secret1",
      "APP/SECRET2" => "secret2"
    }

    assert_equal expected_json, json
  end

  private

  def run_command(*command)
    stdouted do
      Kamal::Cli::Secrets.start \
        [*command,
          "-c", "test/fixtures/deploy_with_accessories.yml",
          "--adapter", "dashlane",
          "--account", "email@example.com"]
    end
  end

  def single_item_json
    <<~JSON
      [
        {
          "id": "1234567891234567891",
          "title": "SECRET1",
          "content": "secret1",
          "creationDatetime": "1724926635",
          "lastBackupTime": "1724926635",
          "lastUse": "1724926635",
          "localeFormat": "UNIVERSAL",
          "spaceId": "123456",
          "userModificationDatetime": "1724926635",
          "secured": "false"
        }
      ]
    JSON
  end
end
