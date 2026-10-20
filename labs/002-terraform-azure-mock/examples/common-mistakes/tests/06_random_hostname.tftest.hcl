# Mocks invent computed values: default_hostname is not *.azurewebsites.net.
# Error: Test assertion failed ... output.web_app_url is "https://<random>"
mock_provider "azurerm" {
  source = "../../tests/mocks"
}

run "url_format" {
  module {
    source = "../.."
  }

  assert {
    condition     = endswith(output.web_app_url, ".azurewebsites.net")
    error_message = "web_app_url must be an azurewebsites.net URL, got ${output.web_app_url}"
  }
}
