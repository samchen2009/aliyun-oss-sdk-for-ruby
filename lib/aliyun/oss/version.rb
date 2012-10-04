# -*- encoding : utf-8 -*-
module Aliyun
  module OSS
    module VERSION #:nodoc:
      MAJOR    = '0'
      MINOR    = '7'
      TINY     = '0'
      #BETA     = nil # Time.now.to_i.to_s
      BETA     = Time.now.to_i.to_s
    end
    
    Version = [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY, VERSION::BETA].compact * '.'
  end
end
