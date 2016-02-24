require 'test_helper'

class ZDOrganizationTest < ActiveSupport::TestCase
  test 'Organization Names' do
    name = 'my fun org name'
    organization = ZDOrganization.new('name' => name)
    assert_equal name, organization.name, msg: 'A ZDOrganization name did '\
      'not match assigned name'

    organization = ZDOrganization.new({})
    assert_equal '', organization.name, msg: 'A ZDOrganization with no name '\
      'should have the empty string as its name'
  end
end
