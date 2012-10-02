# -*- encoding : utf-8 -*-
module AWS
  module S3
    # By default buckets are private. This means that only the owner has access rights to the bucket and its objects. 
    # Objects in that bucket inherit the permission of the bucket unless otherwise specified. When an object is private, the owner can 
    # generate a signed url that exposes the object to anyone who has that url. Alternatively, buckets and objects can be given other 
    # access levels. Several canned access levels are defined:
    # 
    # * <tt>:private</tt> - Owner gets FULL_CONTROL. No one else has any access rights. This is the default.
    # * <tt>:public_read</tt> - Owner gets FULL_CONTROL and the anonymous principal is granted READ access. If this policy is used on an object, it can be read from a browser with no authentication.
    # * <tt>:public_read_write</tt> - Owner gets FULL_CONTROL, the anonymous principal is granted READ and WRITE access. This is a useful policy to apply to a bucket, if you intend for any anonymous user to PUT objects into the bucket.
    # 
    # You can set a canned access level when you create a bucket or an object by using the <tt>:access</tt> option:
    # 
    #   S3Object.store(
    #     'kiss.jpg', 
    #     data, 
    #     'marcel', 
    #     :access => :public_read
    #   )
    # 
    # Since the image we created is publicly readable, we can access it directly from a browser by going to the corresponding bucket name 
    # and specifying the object's key without a special authenticated url:
    # 
    #  http://oss.aliyuncs.com/marcel/kiss.jpg
    # 
    module ACL
      # The ACL::Policy class lets you inspect and modify access controls for buckets and objects.
      # A policy is made up of one or more Grants which specify a permission and a Grantee to whom that permission is granted.
      #
      # Buckets and objects are given a default access policy which contains one grant permitting the owner of the bucket or object
      # FULL_CONTROL over its contents. This means they can read the object, write to the object, as well as read and write its
      # policy.
      #
      # The <tt>acl</tt> method for both buckets and objects returns the policy object for that entity:
      #
      #   grant = Bucket.acl('some-bucket')
      #   grant = Bucket.acl('some-bucket', :public_read)
      #
      
      module Bucket
        def self.included(klass) #:nodoc:
          klass.extend(ClassMethods)
        end
        
        module ClassMethods
          # The acl method is the single point of entry for reading and writing access control list policies for a given bucket.
          #   
          #   # Fetch the acl for the 'marcel' bucket
          #   policy = Bucket.acl 'marcel'
          #
          #   # Modify the policy ...
          #   # Bucket.acl 'marcel', :public_read
          def acl(name = nil, access_level = nil)
            path = path(name) << '?acl'
            if access_level
              put(path, {:access => access_level})
              acl(name)
            else
              respond_with(Policy::Response) do 
                policy = get(path).policy 
                policy.has_key?('access_control_list') && policy['access_control_list']['grant'][0]
              end
            end
          end
        end
        
        # The acl method returns and updates the acl for a given bucket.
        #
        #   # Fetch a bucket
        #   bucket = Bucket.find 'marcel'
        #
        #   # view
        #   bucket.acl
        #
        #   # write
        #   bucket.acl(:public_read)
        def acl(reload = false)
          expirable_memoize(reload) do
            self.class.acl(name, reload)
          end
        end
      end
      
      class OptionProcessor #:nodoc:
        attr_reader :options
        class << self
          def process!(options)
            new(options).process!
          end
        end

        def initialize(options)
          options.to_normalized_options!
          @options      = options
          @access_level = extract_access_level
        end

        def process!
          return unless access_level_specified?
          validate!
          options['x-oss-acl'] = access_level
        end

        private
          def extract_access_level
             options.delete('access') || options.delete('x-oss-acl')
          end

          def validate!
            raise InvalidAccessControlLevel.new(valid_levels, access_level) unless valid?
          end

          def valid?
            valid_levels.include?(access_level)
          end

          def access_level_specified?
            !@access_level.nil?
          end

          def valid_levels
            %w(private public-read public-read-write)
          end

          def access_level
            @normalized_access_level ||= @access_level.to_header
          end
      end
    end
  end
end
