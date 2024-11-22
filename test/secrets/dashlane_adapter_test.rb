require "test_helper"

class DashlaneAdapterTest < SecretAdapterTestCase
  setup do
    `true` # Ensure $? is 0
  end

  test "fetch" do
    stub_ticks.with("dcli --version 2> /dev/null")
    stub_ticks.with("dcli accounts whoami < /dev/null").returns("email@example.com")

    stub_ticks
      .with("dcli secret SECRET1 FOLDER1/FSECRET1 FOLDER1/FSECRET2 -o json")
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
            "title": "FOLDER1/FSECRET1",
            "content": "fsecret1",
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
            "title": "FOLDER1/FSECRET2",
            "content": "fsecret2",
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

    json = JSON.parse(shellunescape(run_command("fetch", "SECRET1", "FOLDER1/FSECRET1", "FOLDER1/FSECRET2")))

    expected_json = {
      "SECRET1"=>"secret1",
      "FOLDER1/FSECRET1"=>"fsecret1",
      "FOLDER1/FSECRET2"=>"fsecret2"
    }

    assert_equal expected_json, json
  end

  test "fetch with from" do
    stub_ticks.with("dcli --version 2> /dev/null")
    stub_ticks.with("dcli accounts whoami < /dev/null").returns("email@example.com")

    stub_ticks
      .with("dcli secret FOLDER1/FSECRET1 FOLDER1/FSECRET2 -o json")
      .returns(<<~JSON)
        [
          {
            "id": "1234567891234567891",
            "title": "FOLDER1/FSECRET1",
            "content": "fsecret1",
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
            "title": "FOLDER1/FSECRET2",
            "content": "fsecret2",
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

    json = JSON.parse(shellunescape(run_command("fetch", "--from", "FOLDER1", "FSECRET1", "FSECRET2")))

    expected_json = {
      "FOLDER1/FSECRET1"=>"fsecret1",
      "FOLDER1/FSECRET2"=>"fsecret2"
    }

    assert_equal expected_json, json
  end

  test "fetch with signin" do
    stub_ticks.with("dcli --version 2> /dev/null")
    stub_ticks_with("dcli accounts whoami < /dev/null", succeed: false).returns("")
    stub_ticks_with("(echo email@example.com; cat) | dcli sync").returns("")
    stub_ticks.with("dcli secret SECRET1 -o json").returns(single_item_json)

    json = JSON.parse(shellunescape(run_command("fetch", "SECRET1")))

    expected_json = {
      "SECRET1"=>"secret1"
    }

    assert_equal expected_json, json
  end

  test "fetch without CLI installed" do
    stub_ticks_with("dcli --version 2> /dev/null", succeed: false)

    error = assert_raises RuntimeError do
      JSON.parse(shellunescape(run_command("fetch", "SECRET1")))
    end
    assert_equal "Dashlane CLI is not installed", error.message
  end

  private
    def run_command(*command)
      stdouted do
        Kamal::Cli::Secrets.start \
          [ *command,
            "-c", "test/fixtures/deploy_with_accessories.yml",
            "--adapter", "dashlane",
            "--account", "email@example.com" ]
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
