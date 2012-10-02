# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/test_helper'

class RemoteACLTest < Test::Unit::TestCase
  
  def setup
    establish_real_connection
  end
  
  def teardown
    disconnect!
  end
  
  def test_acl
    Bucket.create(TEST_BUCKET) 
    Bucket.acl(TEST_BUCKET, :private) # Wipe out the existing bucket's ACL
      
    bucket_policy = Bucket.acl(TEST_BUCKET)
    assert_equal 'private', bucket_policy
    
    assert_nothing_raised do
      Bucket.acl(TEST_BUCKET, :public_read)
    end
    
    bucket = Bucket.find(TEST_BUCKET)
    assert_equal 'public-read', bucket.acl
  end
end
