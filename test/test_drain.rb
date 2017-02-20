require 'helper'
require 'drain'

class TestDrain < Minitest::Test

  def test_version
    version = Drain.const_get('VERSION')

    assert(!version.empty?, 'should have a VERSION constant')
  end

end
