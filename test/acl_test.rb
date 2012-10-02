# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/test_helper'

class ACLOptionProcessorTest < Test::Unit::TestCase
  def test_empty_options
    options = {}
    assert_nothing_raised do
      process! options
    end
    assert_equal({}, options)
  end
  
  def test_invalid_access_level
    options = {:access => :foo}
    assert_raises(InvalidAccessControlLevel) do
      process! options
    end
  end
  
  def test_valid_access_level_is_normalized
    valid_access_levels = [
      {:access     => :private},
      {'access'    => 'private'},
      {:access     => 'private'},
      {'access'    => :private},
      {'x-oss-acl' => 'private'},
      {:x_oss_acl  => :private},
      {:x_oss_acl  => 'private'},
      {'x_oss_acl' => :private}
    ]
    
    valid_access_levels.each do |options|
      assert_nothing_raised do
        process! options
      end
      assert_equal 'private', acl(options)
    end
    
    valid_hyphenated_access_levels = [
      {:access     => :public_read},
      {'access'    => 'public_read'},
      {'access'    => 'public-read'},
      {:access     => 'public_read'},
      {:access     => 'public-read'},
      {'access'    => :public_read},
      
      {'x-oss-acl' => 'public_read'},
      {:x_oss_acl  => :public_read},
      {:x_oss_acl  => 'public_read'},
      {:x_oss_acl  => 'public-read'},
      {'x_oss_acl' => :public_read}
    ]
    
    valid_hyphenated_access_levels.each do |options|
      assert_nothing_raised do
        process! options
      end
      assert_equal 'public-read', acl(options)
    end
  end
  
  private
    def process!(options)
      ACL::OptionProcessor.process!(options)
    end
    
    def acl(options)
      options['x-oss-acl']
    end
end
