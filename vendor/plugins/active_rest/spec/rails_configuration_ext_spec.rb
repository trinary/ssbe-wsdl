require 'pathname'
require Pathname(__FILE__).dirname + 'spec_helper'

module Rails
  module Configuration
  end
end

require 'rails_configuration_ext'

describe ActiveRest::RailsConfigurator do
  before do
    @conf = ActiveRest::RailsConfigurator.new
  end
  
  it 'should allow well known URIs to be declared' do
    @conf.my_special_uri = "http://myhost.example/foo/bar"
    
    named_uris = mock('named_uris')
    ActiveRest.expects(:named_uris).returns(named_uris)
    named_uris.expects(:[]=).with(:my_special, "http://myhost.example/foo/bar")

    @conf.configure_active_rest    
  end 

  it 'should allow multiple declaration of the same named URI with the last one winning' do
    @conf.my_special_uri = "http://myhost.example/foo/bar"
    @conf.my_special_uri = "http://prod.myhost.example/foo/bar"

    named_uris = mock('named_uris')
    ActiveRest.expects(:named_uris).returns(named_uris)
    named_uris.expects(:[]=).with(:my_special, "http://prod.myhost.example/foo/bar")
    
    @conf.configure_active_rest    
  end 

  it 'should allow declaration of auth credentials' do
    @conf.auth_credentials << {:realm => 'MyApp', :account => 'a_user', :password => 'resu_a'}
    
    ActiveRest.expects(:auth_credentials).with(:realm => 'MyApp', :account => 'a_user', :password => 'resu_a')
    
    @conf.configure_active_rest    
  end
  
  it 'should allow multiple declarations of auth credentials for the same realm with the last one winning' do
    @conf.auth_credentials << {:realm => 'MyApp', :account => 'a_user', :password => 'resu_a'}
    @conf.auth_credentials << {:realm => 'MyApp', :account => 'a_user', :password => 'super secret'}
    
    ActiveRest.expects(:auth_credentials).with(:realm => 'MyApp', :account => 'a_user', :password => 'super secret')
    
    @conf.configure_active_rest    
  end 

  
end 
