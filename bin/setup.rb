# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby
if ENV['OSS_ACCESS_KEY_ID'] && ENV['OSS_SECRET_ACCESS_KEY']
  Aliyun::OSS::Base.establish_connection!(
    :access_key_id     => ENV['OSS_ACCESS_KEY_ID'], 
    :secret_access_key => ENV['OSS_SECRET_ACCESS_KEY']
  )
end

require File.dirname(__FILE__) + '/../test/fixtures'
include Aliyun::OSS
