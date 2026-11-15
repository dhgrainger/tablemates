require "test_helper"

class ReceiptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:dinner)
    @wine = contributions(:wine)
    @wine.receipt.attach(io: file_fixture("cover.png").open, filename: "receipt.png")
  end

  test "anyone at the party can view a receipt" do
    visit_as_guest invitations(:cal)
    get party_contribution_receipt_path(@event, @wine)

    assert_response :success
    assert_equal "image/png", response.media_type
  end

  test "strangers and guests of other parties cannot" do
    get party_contribution_receipt_path(@event, @wine)
    assert_response :not_found

    visit_as_guest invitations(:eve)
    get party_contribution_receipt_path(@event, @wine)
    assert_response :not_found

    get party_contribution_receipt_path(events(:brunch), @wine)
    assert_response :not_found
  end

  test "no receipt is a 404" do
    visit_as_guest invitations(:cal)
    get party_contribution_receipt_path(@event, contributions(:tiramisu))
    assert_response :not_found
  end
end
