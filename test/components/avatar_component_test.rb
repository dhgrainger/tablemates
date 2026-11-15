require "test_helper"

class AvatarComponentTest < ViewComponent::TestCase
  test "renders initials from the first two words" do
    render_inline AvatarComponent.new(name: "bea baker cook")
    assert_text "BB"
  end

  test "falls back to a question mark" do
    render_inline AvatarComponent.new(name: "")
    assert_text "?"
  end
end
