require 'test_helper'

class ZDObjectTest < ActiveSupport::TestCase
  test 'ZDObject With Bad Input' do
    assert_raises(ArgumentError) do
      ZDObject.new([])
    end
  end

  test 'Empty ZDObject' do
    object = ZDObject.new({})
    assert !object.valid?, msg: 'Empty ZDObject should be invalid'
    assert_equal object.id, '', msg: 'Empty ZDObject should have no id'
  end

  test 'Valid ZDObject' do
    object_id = 54
    object_hash = { 'id' => object_id }
    object = ZDObject.new(object_hash)
    assert object.valid?, msg: 'Object with an ID should be valid'
    assert_equal object_id.to_s, object.id, msg: 'Object with an ID should '\
      'have ID equal to instantiated value'
  end
end
