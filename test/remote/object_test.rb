# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/test_helper'

class RemoteOSSObjectTest < Test::Unit::TestCase
  def setup
    establish_real_connection
  end
  
  def teardown
    disconnect!
  end
  
  def test_object
    key                 = 'testing_ossobjects'
    value               = 'testing'
    content_type        = 'text/plain'
    unauthenticated_url = ['http:/', Base.connection.http.address, TEST_BUCKET, key].join('/')
    
    # Create an object
    
    response = nil
    assert_nothing_raised do
      response = OSSObject.create(key, value, TEST_BUCKET, :content_type => content_type)
    end
    
    # Check response
    
    assert response.success?
    
    # Extract the object's etag
    
    etag = nil
    assert_nothing_raised do
      etag = response.etag
    end
    
    assert etag
    
    # Confirm we can't create an object unless the bucket is set
    
    assert_raises(NoBucketSpecified) do
      object = OSSObject.new
      object.key = 'hello'
      object.store
    end
    
    # Fetch newly created object to show it was actually created
    
    object = nil
    assert_nothing_raised do
      object = OSSObject.find(key, TEST_BUCKET)
    end
    
    assert object
    
    # Confirm it has the right etag
    
    assert_equal etag, object.etag
    
    # Check if its owner is properly set
    
    assert_nothing_raised do
      object.owner.display_name
    end
    
    # Confirm we can get the object's key
    
    assert_equal key, object.key
    
    # Confirm its value was properly set
    
    assert_equal value, object.value
    assert_equal value, OSSObject.value(key, TEST_BUCKET)
    streamed_value = ''
    assert_nothing_raised do
      OSSObject.stream(key, TEST_BUCKET) do |segment|
        streamed_value << segment
      end
    end
    
    assert_equal value, streamed_value
    
    # Change its value
    
    new_value = "<script>alert('foo');</script>"
    assert_nothing_raised do
      object.value = new_value
    end
    assert_equal new_value, object.value
    
    # Confirm content type was properly set
    
    assert_equal content_type, object.content_type
    
    # Change its content type
    
    new_content_type = 'text/javascript'
    assert_nothing_raised do
      object.content_type = new_content_type
    end
    
    assert_equal new_content_type, object.content_type
    
    # Test that it is publicly readable
    
    Bucket.acl(TEST_BUCKET, :public_read)
    response = fetch_object_at(unauthenticated_url)
    assert (200..299).include?(response.code.to_i)
    
    # Confirm that it has no meta data
    
    assert object.metadata.empty?
    
    # Set some meta data
    
    metadata_key   = :secret_sauce
    metadata_value = "it's a secret"
    object.metadata[metadata_key] = metadata_value
    
    # Persist all changes
    
    assert_nothing_raised do
      object.store
    end
    
    # Refetch the object
    
    key = object.key
    object = nil
    assert_nothing_raised do
      object = OSSObject.find(key, TEST_BUCKET)
    end
    
    # Confirm all changes were persisted
    
    assert object
    assert_equal key, object.key
    
    assert_equal new_content_type, object.content_type
    
    assert_equal new_value, object.value
    assert_equal new_value, object.value(:reload)
    
    assert !object.metadata.empty?
    assert_equal metadata_value, object.metadata[metadata_key]
    
    # Change acl
    
    Bucket.acl(TEST_BUCKET, :private)
    
    # Confirm object is no longer publicly readable
    
    response = fetch_object_at(unauthenticated_url)
    assert (400..499).include?(response.code.to_i)
    
    # Confirm object is accessible from its authenticated url
    
    response = fetch_object_at(object.url)
    assert (200..299).include?(response.code.to_i)
    
    # Copy the object
    
    assert_nothing_raised do
      object.copy('testing_ossobjects-copy')
    end
    
    # Confirm the object is identical
    
    copy = nil
    assert_nothing_raised do
      copy = OSSObject.find('testing_ossobjects-copy', TEST_BUCKET)
    end
    
    assert copy
    
    assert_equal object.value, copy.value
    assert_equal object.content_type, copy.content_type
    
    # Delete object
    
    assert_nothing_raised do
      object.delete
    end
    
    # Confirm we can rename objects
    
    renamed_to = copy.key + '-renamed'
    renamed_value = copy.value
    assert_nothing_raised do
      OSSObject.rename(copy.key, renamed_to, TEST_BUCKET)
    end
    
    # Confirm renamed copy exists
    
    renamed = nil
    assert_nothing_raised do
      renamed = OSSObject.find(renamed_to, TEST_BUCKET)
    end
    
    assert renamed
    assert_equal renamed_value, renamed.value
    
    # Confirm copy is deleted
    
    assert_raises(NoSuchKey) do
      OSSObject.find(copy.key, TEST_BUCKET)
    end
    
    # Confirm that you can not store an object once it is deleted
    
    assert_raises(DeletedObject) do
      object.store
    end
    
    assert_raises(NoSuchKey) do
      OSSObject.find(key, TEST_BUCKET)
    end
    
    # Confirm we can pass in an IO stream and have the uploading sent in chunks
    
    response = nil
    test_file_key = File.basename(TEST_FILE)
    assert_nothing_raised do
      response = OSSObject.store(test_file_key, open(TEST_FILE), TEST_BUCKET)
    end
    assert response.success?
    
    assert_equal File.size(TEST_FILE), Integer(OSSObject.about(test_file_key, TEST_BUCKET)['content-length'])
    
    result = nil
    assert_nothing_raised do
      result = OSSObject.delete(test_file_key, TEST_BUCKET)
    end
    
    assert result
  end
    
  def test_content_type_inference
    # Confirm appropriate content type is inferred when not specified

    content_type_objects = {'foo.jpg' => 'image/jpeg', 'no-extension-specified' => 'binary/octet-stream', 'foo.txt' => 'text/plain'}
    content_type_objects.each_key  do |key|
      OSSObject.store(key, 'fake data', TEST_BUCKET) # No content type explicitly set
    end

    content_type_objects.each do |key, content_type|
      assert_equal content_type, OSSObject.about(key, TEST_BUCKET)['content-type']
    end
    
    # Confirm we can update the content type
    
    assert_nothing_raised do
      object = OSSObject.find('no-extension-specified', TEST_BUCKET)
      object.content_type = 'application/pdf'
      object.store
    end
    
    assert_equal 'application/pdf', OSSObject.about('no-extension-specified', TEST_BUCKET)['content-type']
    
  ensure
    # Get rid of objects we just created
    content_type_objects.each_key {|key| OSSObject.delete(key, TEST_BUCKET) }
  end
  
  def test_body_can_be_more_than_just_string_or_io
    require 'stringio'
    key = 'testing-body-as-string-io'
    io = StringIO.new('hello there')
    OSSObject.store(key, io, TEST_BUCKET)
    assert_equal 'hello there', OSSObject.value(key, TEST_BUCKET)
  ensure
    OSSObject.delete(key, TEST_BUCKET)
  end
  
  def test_fetching_information_about_an_object_that_does_not_exist_raises_no_such_key
    assert_raises(NoSuchKey) do
      OSSObject.about('asdfasdfasdfas-this-does-not-exist', TEST_BUCKET)
    end
  end
  
  # Regression test for http://developer.aliyunwebservices.com/connect/thread.jspa?messageID=49152&tstart=0#49152
  def test_finding_an_object_with_slashes_in_its_name_does_not_escape_the_slash
    OSSObject.store('rails/1', 'value does not matter', TEST_BUCKET)
    OSSObject.store('rails/1.html', 'value does not matter', TEST_BUCKET)
    
    object = nil
    assert_nothing_raised do
      object = OSSObject.find('rails/1.html', TEST_BUCKET)
    end
    
    assert_equal 'rails/1.html', object.key
  ensure
    %w(rails/1 rails/1.html).each {|key| OSSObject.delete(key, TEST_BUCKET)}
  end
  
  def test_finding_an_object_with_spaces_in_its_name    
    assert_nothing_raised do
      OSSObject.store('name with spaces', 'value does not matter', TEST_BUCKET)
    end
    
    object = nil
    assert_nothing_raised do
      object = OSSObject.find('name with spaces', TEST_BUCKET)
    end
    
    assert object
    assert_equal 'name with spaces', object.key
    
    # Confirm authenticated url is generated correctly despite space in file name
    
    response = fetch_object_at(object.url)
    assert (200..299).include?(response.code.to_i)
    
  ensure
    OSSObject.delete('name with spaces', TEST_BUCKET)
  end
  
  def test_handling_a_path_that_is_not_valid_utf8
    key = "318597/620065/GTL_75\24300_A600_A610.zip"
    assert_nothing_raised do
      OSSObject.store(key, 'value does not matter', TEST_BUCKET)
    end
    
    object = nil
    assert_nothing_raised do
      object = OSSObject.find(key, TEST_BUCKET)
    end

    assert object
    
    url = nil
    assert_nothing_raised do
      url = OSSObject.url_for(key, TEST_BUCKET)
    end
    
    assert url
    
    assert_equal object.value, fetch_object_at(url).body
  ensure
    assert_nothing_raised do
      OSSObject.delete(key, TEST_BUCKET)
    end
  end
  
  private
    def fetch_object_at(url)
      Net::HTTP.get_response(URI.parse(url))
    end
    
end
