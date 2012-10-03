# -*- encoding : utf-8 -*-
require 'cgi'
require 'uri'
require 'openssl'
require 'digest/sha1'
require 'net/https'
require 'time'
require 'date'
require 'open-uri'

$:.unshift(File.dirname(__FILE__))
require 'oss/extensions'
require_library_or_gem 'builder' unless defined? Builder
require_library_or_gem 'mime/types', 'mime-types' unless defined? MIME::Types

require 'oss/base'
require 'oss/version'
require 'oss/parsing'
require 'oss/acl'
require 'oss/logging'
require 'oss/service'
require 'oss/owner'
require 'oss/bucket'
require 'oss/object'
require 'oss/error'
require 'oss/exceptions'
require 'oss/connection'
require 'oss/authentication'
require 'oss/response'

Aliyun::OSS::Base.class_eval do
  include Aliyun::OSS::Connection::Management
end

Aliyun::OSS::Bucket.class_eval do
  include Aliyun::OSS::Logging::Management
  include Aliyun::OSS::ACL::Bucket
end

require_library_or_gem 'xmlsimple', 'xml-simple' unless defined? XmlSimple
# If libxml is installed, we use the FasterXmlSimple library, that provides most of the functionality of XmlSimple
# except it uses the xml/libxml library for xml parsing (rather than REXML). If libxml isn't installed, we just fall back on
# XmlSimple.
Aliyun::OSS::Parsing.parser =
  begin
    require_library_or_gem 'xml/libxml'
    # Older version of libxml aren't stable (bus error when requesting attributes that don't exist) so we
    # have to use a version greater than '0.3.8.2'.
    raise LoadError unless XML::Parser::VERSION > '0.3.8.2'
    $:.push(File.join(File.dirname(__FILE__), '..', '..', 'support', 'faster-xml-simple', 'lib'))
    require_library_or_gem 'faster_xml_simple' 
    FasterXmlSimple
  rescue LoadError
    XmlSimple
  end
