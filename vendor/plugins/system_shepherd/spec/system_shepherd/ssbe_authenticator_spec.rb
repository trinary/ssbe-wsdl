require 'pathname'
require Pathname(__FILE__).dirname + '../spec_helper'

require 'system_shepherd/ssbe_authenticator'

describe SSBEAuthenticator do
  before do
    @auth = SSBEAuthenticator.new('admin', '12345')

    @chal = mock('Response', :uri => 'http://example.com/login')
    @valid_auth_header = 'Digest nonce="1234", qop="auth", opaque="5678", algorithm=MD5-sess, realm="SystemShepherd"'
    @chal.stub!(:header).and_return(@header = mock('header', :[] => [@valid_auth_header]))

    @req = mock('Request', :uri => 'http://example.com')
  end

  [:update_credentials, :valid_for?, :can_handle?, :add_credentials_to].each do |meth|
    it "should have a #{meth} method" do
      @auth.should respond_to(meth)
    end
  end

  describe 'initialization' do
    it 'should set the username from the args' do
      @auth.username.should == 'admin'
    end

    it 'should set the password from the args' do
      @auth.password.should == '12345'
    end

    it 'should set the realm to "SystemShepherd"' do
      @auth.realm.should == 'SystemShepherd'
    end

    it 'should initialize domain to nil' do
      @auth.domain.should be_nil
    end
  end

  describe 'update_credentials' do
    it 'should set the domain to the host part of the challenge\'s uri' do
      @auth.update_credentials(@chal)
      @auth.domain.should == 'example.com'
    end

    it 'should parse the auth header into a HTTPAuth::Digest::Challenge object' do
      @auth.update_credentials(@chal)
      @auth.challenge.should be_kind_of(HTTPAuth::Digest::Challenge)
    end
  end

  describe '#valid_for?' do
    it 'should not be valid for a challenge that does not have a WWW-Authenticate header' do
      @header.should_receive(:[]).with('WWW-Authenticate').and_return(nil)
      @auth.valid_for?(@chal).should be_false
    end

    it 'should not be valid for a challenge that does not have well-formed WWW-Authenticate header' do
      @header.should_receive(:[]).with('WWW-Authenticate').and_return(['foobar'])
      @auth.valid_for?(@chal).should be_false
    end

    it 'should not be valid for a challenge that does not have a realm of "SystemShepherd"' do
      @header.should_receive(:[]).with('WWW-Authenticate').and_return(['Digest realm=NotSysShep'])
      @auth.valid_for?(@chal).should be_false
    end

    it 'should not be valid for a challenge that doesn not have a scheme of digest' do
      @header.should_receive(:[]).with('WWW-Authenticate').and_return(['FooBar realm=NotSysShep'])
      @auth.valid_for?(@chal).should be_false
    end

    it 'should be valid for a valid challenge' do
      @header.should_receive(:[]).with('WWW-Authenticate').and_return([@valid_auth_header])
      @auth.valid_for?(@chal).should be_true
    end
  end

  describe '#can_handle?' do
    before do
      @auth.update_credentials(@chal)
    end

    it 'should not handle requests for a different domain' do
      @req.stub!(:uri).and_return('http://not.example.com')
      @auth.can_handle?(@req).should be_false
    end

    it 'should handle requests for the same domain' do
      @req.stub!(:uri).and_return('http://example.com')
      @auth.can_handle?(@req).should be_true
    end
  end

  describe '#add_credentials_to' do
    before do
      @auth.update_credentials(@chal)

      @header = mock('header', :[]= => nil)
      @req.stub!(:header).and_return(@header)
      @req.stub!(:method).and_return('GET')
    end

    it 'should add the credentials to the request\'s authorization header' do
      @header.should_receive(:[]=).with('Authorization', /Digest/)
      @auth.add_credentials_to(@req)
    end

  end



end
