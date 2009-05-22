require 'pathname'
require Pathname(__FILE__).dirname + '../spec_helper'

require 'resourceful/http_accessor'

describe Resourceful::HttpAccessor, 'init' do
    
  it 'should be instantiatable' do
    Resourceful::HttpAccessor.new().should be_instance_of(Resourceful::HttpAccessor)
  end 
  
  it 'should accept logger to new' do
    ha = Resourceful::HttpAccessor.new(:logger => (l = stub('logger')))
    
    ha.logger.should == l
  end 

  it 'should provide logger object even when no logger is specified' do
    ha = Resourceful::HttpAccessor.new()
    
    ha.logger.should be_instance_of(Resourceful::BitBucketLogger)
  end 

  it 'should raise arg error if unrecognized options are passed' do
    lambda {
      Resourceful::HttpAccessor.new(:foo => 'foo', :bar => 'bar')
    }.should raise_error(ArgumentError, /Unrecognized options: (foo, bar)|(bar, foo)/)
  end 

  it 'should allow an additional user agent token to be passed at init' do
    ha = Resourceful::HttpAccessor.new(:user_agent => "Super/3000")

    ha.user_agent_string.should match(%r{^Super/3000})
  end 

  it 'should allow multiple additional user agent tokens to be passed at init' do
    ha = Resourceful::HttpAccessor.new(:user_agent => ["Super/3000", "Duper/2.1"])

    ha.user_agent_string.should match(%r{^Super/3000 Duper/2\.1 })
  end 

  it 'should allow cache manager to be provided at init' do
    ha = Resourceful::HttpAccessor.new(:cache_manager => :marker)

    ha.cache_manager.should equal(:marker)
  end 

end 

describe Resourceful::HttpAccessor do 
  before do
    @logger = stub('logger')
    @accessor = Resourceful::HttpAccessor.new(:logger => @logger)
    @auth_manager = mock('authentication_manager')
    Resourceful::AuthenticationManager.stub!(:new).and_return(@auth_manager)

    @resource = mock('resource')
    Resourceful::Resource.stub!(:new).and_return(@resource)
  end
  
  it 'should have user agent string w/ just resourceful token by default' do
    @accessor.user_agent_string.should == "Resourceful/#{RESOURCEFUL_VERSION}(Ruby/#{RUBY_VERSION})"
  end 
  
  it 'should add additional user agent tokens to beginning of user agent string' do
    @accessor.user_agent_tokens << 'FooBar/3000(special-version)'
    
    @accessor.user_agent_string.should match(%r{^FooBar\/3000\(special-version\) Resourceful/})
  end
  
  it 'should allow a logger to be specified' do
    l = stub('logger')
    
    @accessor.logger = l
    @accessor.logger.should == l
  end 

  it 'should allow a logger to be removed' do
    l = stub('logger')
    
    @accessor.logger = l
    @accessor.logger = nil
    @accessor.logger.should be_nil    
  end 

  it 'should be able to return a particular resource (#[])' do
    @accessor['http://www.example/'].should == @resource
  end 

  it 'should create resource if it does not already exist (#[])' do
    Resourceful::Resource.should_receive(:new).and_return(stub('resource'))
    @accessor['http://www.example/previously-unused-uri']
  end 

  it 'should pass uri to resource upon creation (#[])' do
    Resourceful::Resource.should_receive(:new).with(anything, 'http://www.example/previously-unused-uri', anything).
      and_return(stub('resource'))
    @accessor['http://www.example/previously-unused-uri']
  end 
  
  it 'should pass owning accessor to resource upon creation (#[])' do
    Resourceful::Resource.should_receive(:new).with(@accessor, anything, anything).and_return(stub('resource'))
    @accessor['http://www.example/previously-unused-uri']
  end 

  it 'should be able to return a particular resource (#resource)' do
    @accessor.resource('http://www.example/').should == @resource
  end 

  it 'should create resource if it does not already exist (#resource)' do
    Resourceful::Resource.should_receive(:new).and_return(stub('resource'))
    @accessor.resource('http://www.example/previously-unused-uri')
  end 

  it 'should pass owning accessor to resource upon creation (#[])' do
    Resourceful::Resource.should_receive(:new).with(@accessor, anything, anything).and_return(stub('resource'))
    @accessor.resource('http://www.example/previously-unused-uri')
  end 

  it 'should pass uri to resource upon creation (#resource)' do
    Resourceful::Resource.should_receive(:new).with(anything, 'http://www.example/previously-unused-uri', anything).
      and_return(stub('resource'))
    @accessor.resource('http://www.example/previously-unused-uri')
  end 

  it 'should pass additional options to resource upon creation' do
    Resourceful::Resource.should_receive(:new).with(anything, anything, :foo => :bar).and_return(stub('resource'))
    @accessor.resource('http://example.com/', :foo => :bar)
  end

end

describe Resourceful::HttpAccessor, "(authentication)" do           
  before do
    @auth_manager = stub('auth_manager', :add_auth_handler => nil)
    Resourceful::AuthenticationManager.stub!(:new).and_return(@auth_manager)
    @ha = Resourceful::HttpAccessor.new()
  end

  it 'should allow authenticators to be registered' do
    an_authenticator = stub('an_authenicator')
    @auth_manager.should_receive(:add_auth_handler).with(an_authenticator)

    @ha.add_authenticator(an_authenticator)
  end 

  it 'should allow an authenicator to be specified at init' do
    an_authenticator = stub('an_authenicator')
    @auth_manager.should_receive(:add_auth_handler).with(an_authenticator)

    Resourceful::HttpAccessor.new(:authenticator => an_authenticator)
  end 

  it 'should allow multiple authenicators to be specified at init' do
    authenticator1 = stub('authenicator1')
    authenticator2 = stub('authenicator2')

    @auth_manager.should_receive(:add_auth_handler).with(authenticator1)
    @auth_manager.should_receive(:add_auth_handler).with(authenticator2)

    Resourceful::HttpAccessor.new(:authenticators => [authenticator1, authenticator2])
  end 

end 
