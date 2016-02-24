require 'test_helper'

class ZDUserTest < ActiveSupport::TestCase
  test 'User Names' do
    name = 'my fun user name'
    user = ZDUser.new('name' => name)
    assert_equal name, user.name, msg: 'A ZDUser name did not match '\
      'assigned name'

    organization = ZDUser.new({})
    assert_equal '', organization.name, msg: 'A ZDUser with no name '\
      'should have the empty string as its name'
  end

  test 'User Email Addresses' do
    email_address = 'my_user_name@my_domain.com'
    user = ZDUser.new('email' => email_address)
    assert_equal user.email, email_address, msg: 'A ZDUser email '\
      'address should equal the assigned value'

    user = ZDUser.new({})
    assert_equal user.email, '', msg: 'A ZDUser with no assigned '\
      'email address should report the empty string as its email_address'
  end
end
