# -*- encoding : utf-8 -*-
require 'test/unit'
require 'uri'
$:.unshift File.dirname(__FILE__) + '/../../lib'
require 'aliyun/oss'
begin
  require_library_or_gem 'breakpoint'
rescue LoadError
end

TEST_BUCKET = 'aliyun-oss-tests'
TEST_FILE   = File.dirname(__FILE__) + '/test_file.data'

class Test::Unit::TestCase
  include Aliyun::OSS
  def establish_real_connection
    Base.establish_connection!(
      :access_key_id     => ENV['OSS_ACCESS_KEY_ID'], 
      :secret_access_key => ENV['OSS_SECRET_ACCESS_KEY']
    )
  end
  
  def disconnect!
    Base.disconnect
  end
  
  class TestBucket < Bucket
    set_current_bucket_to TEST_BUCKET
  end
  
  class TestOSSObject < OSSObject
    set_current_bucket_to TEST_BUCKET
  end
end
