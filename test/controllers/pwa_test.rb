require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "serves a manifest and a service worker without signing in" do
    get pwa_manifest_path(format: :json)
    assert_response :success
    assert_equal "Tablemates", response.parsed_body["name"]

    get pwa_service_worker_path(format: :js)
    assert_response :success
  end

  test "pages link to the manifest" do
    get root_path
    assert_select "link[rel=manifest][href=?]", pwa_manifest_path(format: :json)
  end
end
