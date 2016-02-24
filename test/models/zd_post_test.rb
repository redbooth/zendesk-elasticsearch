require 'test_helper'

class ZDPostTest < ActiveSupport::TestCase
  test 'Public/Private posts' do
    public_status = false
    post = ZDPost.new('public' => public_status)
    assert_equal public_status, post.public?, msg: 'A ZDPost public status '\
      'did not match its assigned status'
    assert_equal post.public?, !post.private?, msg: 'A ZDPost is both public '\
      'and private. That must not happen'

    post = ZDPost.new({})
    assert_equal true, post.public?, msg: 'A ZDPost with no defined '\
      'public/private status should default to public'
  end

  test 'HTML Body Contents' do
    html_body = '<div> stuff </div>'
    post = ZDPost.new('html_body' => html_body)
    assert_equal post.html_body, html_body, msg: 'A ZDPost html_body '\
      'should equal the assigned value'

    post = ZDPost.new({})
    assert_equal post.html_body, '', msg: 'A ZDPost with no assigned '\
      'html_body should report the empty string as its body'
  end
end
