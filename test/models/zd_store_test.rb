require 'test_helper'

class ZDStoreTest < ActiveSupport::TestCase
  test 'ZDStore With Bad Input' do
    store = ZDStore.new('', Object, '')
    assert_raises(ArgumentError) do
      store.get_objects('')
    end
  end
end
