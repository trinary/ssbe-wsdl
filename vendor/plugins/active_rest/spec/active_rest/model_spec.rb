require 'pathname'
require Pathname(__FILE__).dirname + "../spec_helper"

require 'active_rest/model'
require "active_rest/ssj_transmuter"

describe ActiveRest::Model do
  before do
    @model_class = Class.new(ActiveRest::Model) do
      properties :goodness, :length 
      properties :r_only, :readonly => true
    end
    @model = @model_class.new
  end

  it 'should provide an HttpAccessor' do
    ActiveRest::Model.http.should be_instance_of(Resourceful::HttpAccessor)
  end 

  it "should be instantiatable from hash including readonly fields" do
    a_model = @model_class.new(:length=>10, :goodness=>"superb", :r_only => :marker)
    
    a_model.r_only.should == :marker
  end
  
  it "should be instantiatable from hash" do
    a_model = @model_class.new(:length=>10, :goodness=>"superb")

    a_model.should be_kind_of(@model_class)
    a_model.properties.should == {:length=>10, :goodness=>"superb"}
  end

  it "should be instantiatable with no additional information" do
    a_model = @model_class.new

    a_model.should be_kind_of(@model_class)
  end

  it 'should call class collection_uri method inside instance collection_uri method' do
    @model_class.expects(:collection_uri).returns(:marker)
    @model.collection_uri.should == :marker
  end 
  
  it 'should allow collection resource to be specified as URI string' do
    @model_class.send(:collection_resource, "http://www.example/super-special-blizzos")
    @model_class.collection_uri.should == 'http://www.example/super-special-blizzos'    
  end 

  it 'should allow collection resource to be specified as URI returning Proc' do
    @model_class.send(:collection_resource, lambda{"http://www.example/extra-special-blizzos"})
    @model_class.collection_uri.should == 'http://www.example/extra-special-blizzos'    
  end 

  it 'should allow collection resource to be specified as URI returning block' do
    @model_class.send(:collection_resource){"http://www.example/plain-blizzos"}
    @model_class.collection_uri.should == 'http://www.example/plain-blizzos'    
  end 


  it 'should know if is a new resource' do
    @model.new?.should be_true
  end
  
  it 'should have an href attribute containing nil if model is new' do
    @model.href.should be_nil
  end 
  
  it 'should have valid? method' do
    @model.should respond_to(:valid?)
  end 
  
  it 'should not share validations between unrelated models' do
    another_model_class = Class.new(ActiveRest::Model) do 
      property :foo
    end

    @model_class.class_eval do 
      validates_presence_of :goodness
    end
    
    another_model_class.new.should be_valid
    @model.should_not be_valid
  end 
end

describe ActiveRest::Model, '#save()' do
  before do
    @m_class = Class.new(ActiveRest::Model) do 
      collection_resource 'http://www.example/things'
      property :hello
    end

    @m = @m_class.new
    @m.stubs(:create_resource)
  end  
  
  it 'should call valid? before doing the save' do
    @m.expects(:valid?).returns(true)
    
    @m.save
  end 
  
  it 'should raise ActiveRest::ModelInvalid if model is not valid' do
    @m.expects(:valid?).returns(false)
    
    lambda {
      @m.save
    }.should raise_error(ActiveRest::ModelInvalid)
  end 
end 

describe ActiveRest::Model, '#save() for a new resource' do
  before do
    @m_class = Class.new(ActiveRest::Model) do 
      collection_resource 'http://www.example/things'
      property :hello
    end

    @m = @m_class.new
    @m.stubs(:reload)

    @created_resp = stub('created_resp', :response => 'oops')
    @created_resp.stubs(:[]).with('location').returns('http://www.example/things/42')
    @created_resp.stubs(:is_a?).with(Net::HTTPCreated).returns(true)
    @collection_resource = stub('collection_resource', :post => @created_resp)
    ActiveRest::Model.http.stubs(:[]).with('http://www.example/things').returns(@collection_resource)
  end
 
  it 'should raise error if http accessor raises RequestFailed' do
    @collection_resource.expects(:post).raises(Resourceful::UnsuccessfulHttpRequestError.new(stub("request", :method => :put, :uri => 'http://example.com/things'), stub("response", :code => 404)))
    
    lambda {
      @m.save
    }.should raise_error
  end 

  it 'should return false if http response is anything other than 201' do 
    noncreated_resp = mock('noncreated_resp')
    noncreated_resp.expects(:is_a?).with(Net::HTTPCreated).returns(false)
    @collection_resource.expects(:post).returns(noncreated_resp)
    
    @m.save.should be_false
  end
  
  it 'should not raise error if the save succeeded' do
    lambda {
      @m.save
    }.should_not raise_error
  end 
  
  it 'should extract the href of the new resource from the location header of the response' do
    @created_resp.expects(:[]).with('location').returns('http://www.example/things/42')
    
    @m.save
  end
  
  it 'should have href after save' do
    @m.save

    @m.href.should == 'http://www.example/things/42'
  end 
  
  it 'should post to default collection' do
    ActiveRest::Model.http.expects(:[]).with("http://www.example/things").
      returns(@collection_resource)
    
    @m.save
  end

  it 'should include SSJ representation in post body' do
    @collection_resource.expects(:post).with(instance_of(String), anything, anything).returns(@created_resp)
    
    @m.save
  end

  it 'should set content type appropriately' do
    @collection_resource.expects(:post).with(anything, 'application/vnd.absolute-performance.sysshep+json', anything).returns(@created_resp)
    
    @m.save
  end
 
end 

describe ActiveRest::Model, '.save() for a existing resource' do
  before do
    @m_class = Class.new(ActiveRest::Model) do 
      collection_resource 'http://www.example/things'
      property :hello
    end

    @m = @m_class.new(:href => "http://www.example/things/42")
    @m.stubs(:reload)

    @ok_resp = stub('ok_resp', :is_a? => false)
    @ok_resp.stubs(:is_a?).with(Net::HTTPOK).returns(true)
    @thing_resource = stub("thing_resource", :put => @ok_resp)
    ActiveRest::Model.http.stubs(:[]).with("http://www.example/things/42").returns(@thing_resource)
    
  end
 
  it 'should raise exception if resource raises RequestFailed' do
    @thing_resource.expects(:put).raises(Resourceful::UnsuccessfulHttpRequestError.new(stub("req", :method => :put, :uri => 'http://example.com/things'), stub("resp", :code => 404)))
    
    lambda {
      @m.save
    }.should raise_error
  end
  

  it 'should return false if http response is anything other than 200 or 204' do 
    accepted_resp = stub('noncreated_resp', :is_a? => false)
    @thing_resource.expects(:put).returns(accepted_resp)
    
    @m.save.should be_false
  end
  
  it 'should not raise exception if the response is OK' do
    @ok_resp.expects(:is_a?).with(Net::HTTPOK).returns(true)

    lambda {
      @m.save
    }.should_not raise_error
  end

  it 'should be successful if the response is No Content' do
    no_content_resp = stub('no_content_resp', :is_a? => false)
    no_content_resp.expects(:is_a?).with(Net::HTTPNoContent).returns(true)    
 
    @thing_resource.expects(:put).with(anything, anything, anything).returns(no_content_resp)

    lambda {
      @m.save
    }.should_not raise_error
  end
  
  it 'should put to resource' do
    ActiveRest::Model.http.expects(:[]).with("http://www.example/things/42").returns(@thing_resource)
    
    @m.save
  end

  it 'should include string representation in post body' do
    @thing_resource.expects(:put).with(instance_of(String), anything, anything).returns(@ok_resp)
    
    @m.save
  end

  it 'should set content type appropriately' do
    @thing_resource.expects(:put).with(anything, 'application/vnd.absolute-performance.sysshep+json', anything).returns(@ok_resp)
    @m.save
  end

  it 'should re-fetch the document for changes' do
    @m.expects(:reload)
    @m.save
  end
 
end 

describe ActiveRest::Model, ".get  (individual model)" do
  before do
    @test_model_class = Class.new(ActiveRest::Model) do 
      properties :id, :length, :goodness
    end
    
    @resp = stub(:code => '200', :[] => "application/vnd.absolute-performance.sysshep+json")

    @test_model_resource = stub("resource", :get => @resp)
    
    ActiveRest::Model.http.stubs(:[]).with("http://example.com/test_models/3").returns(@test_model_resource)

    @resp.
      expects(:body).
      returns(JSON('href' => "http://example.com/test_models/3",
                   'id' => "eafsda-aer-aer-aserasd",
                   'length' => 42,
                   'goodness' => "perfect"))
  end

  it "should be able to get single model using a URI" do
    a_model = TestModel.get("http://example.com/test_models/3")

    a_model.href.should == "http://example.com/test_models/3"
    a_model.id.should == "eafsda-aer-aer-aserasd"
  end

end

describe ActiveRest::Model, ".get  (collection of models)" do
  class TestModel < ActiveRest::Model
    properties :id, :length, :goodness
  end

  before do
    @resp = stub(:code => '200', :[] => "application/vnd.absolute-performance.sysshep+json")

    @collection_resource = stub("collection_resource", :get => @resp)
    
    ActiveRest::Model.http.stubs(:[]).with("http://example.com/test_models").returns(@collection_resource)
    
    @resp.expects(:body).
      returns(JSON('href' => "http://example.com/test_models",
                   'items' =>
                   [{'href' => "http://example.com/test_models/3",
                      'id' => "eafsda-aer-aer-aserasd",
                      'length' => 42,
                      'goodness' => "perfect"},
                    {'href' => "http://example.com/test_models/24",
                      'id' => "eafsda-aer-aer-23af32c",
                      'length' => 13,
                      'goodness' => "weak"}]))
  end

  it "should be able to get a collection of models from a URI" do
    some_models = TestModel.get(:all, :from => "http://example.com/test_models")

    some_models.first.href.should == "http://example.com/test_models/3"
    some_models.first.id.should == "eafsda-aer-aer-aserasd"

    some_models.last.href.should == "http://example.com/test_models/24"
    some_models.last.id.should == "eafsda-aer-aer-23af32c"
  end
end

describe ActiveRest::Model, ".property()" do
  it 'should define public reader method' do
    Class.new(::ActiveRest::Model) do 
      property :foo
    end.public_instance_methods.should include('foo')    
  end 

  it 'should define public setter method' do
    Class.new(::ActiveRest::Model) do 
      property :foo
    end.public_instance_methods.should include('foo=')    
  end 

  it 'should setter method as private if property is readonly' do
    Class.new(::ActiveRest::Model) do 
      property :foo, :readonly => true
    end.private_instance_methods.should include('foo=')    
  end 

  it 'should handle string property names' do
    klass = Class.new(::ActiveRest::Model) do 
      property :foo
    end
    
    klass.public_instance_methods.should include('foo=')    
    klass.public_instance_methods.should include('foo')    
  end 
end

describe ActiveRest::Model, ".properties()" do
  it 'should define public reader methods' do
    klass = Class.new(::ActiveRest::Model) do 
      properties :foo, :bar
    end
    
    klass.public_instance_methods.should include('foo')    
    klass.public_instance_methods.should include('bar')    
  end 

  it 'should define public setter method' do
    klass = Class.new(::ActiveRest::Model) do 
      properties :foo, :bar
    end
    
    klass.public_instance_methods.should include('foo=')    
    klass.public_instance_methods.should include('bar=')    
  end 

  it 'should setter method as private if property is readonly' do
    klass = Class.new(::ActiveRest::Model) do 
      properties :foo, :bar, :readonly => true
    end
    
    klass.private_instance_methods.should include('foo=')    
    klass.private_instance_methods.should include('bar=')    
  end 

  it 'should handle string property names' do
    klass = Class.new(::ActiveRest::Model) do 
      properties :foo, 'bar'
    end
    
    klass.public_instance_methods.should include('foo')    
    klass.public_instance_methods.should include('foo=')    
    klass.public_instance_methods.should include('bar')    
    klass.public_instance_methods.should include('bar=')    
  end 
end


describe ActiveRest::Model do
  class TestModel < ActiveRest::Model
    properties :length, :goodness
  end

  before do
    @model = TestModel.new('href' => "http://host.invalid/foo",
                           'length' => 10,
                           'goodness'=>"superb")
  end

  it "should provide working #hash method" do
    model_a = TestModel.new('href' => "http://host.invalid/foo",
                            'length' => 11,
                            'goodness'=>"weak")

    @model.hash.should == model_a.hash
  end

  it "should base equality on href" do
    model_a = TestModel.new('href' => "http://host.invalid/foo",
                            'length' => 11,
                            'goodness'=>"weak")

    @model.should == model_a
    @model.should eql(model_a)
    @model.should_not equal(model_a)
  end

  it "should symbolize keys on instantiation from hash" do
    @model.should be_kind_of(TestModel)
    @model.properties.should == {:href => "http://host.invalid/foo",
      :length=>10, :goodness=>"superb"}
  end

  it "should have dynamic attribute value retrieval methods" do
    @model.length.should == 10
    @model.goodness.should == 'superb'
  end

  it "should treat attribute value retrievals for non-existent properties as normal method missing failures" do
    lambda {
      @model.nonexistent_attribute
    }.should raise_error(NoMethodError)
  end

  it "should have dynamic attribute setting methods" do
    @model.length = 11
    @model.length.should == 11
    @model.properties[:length].should == 11
  end

  it "should treat attribute setting for non-existent properties as normal method missing failures" do
    lambda {
      @model.nonexistent_attribute = :foo
    }.should raise_error(NoMethodError)
  end
end

describe ActiveRest::Model, "with compound attribute values" do
  before do
    @test_model_class = Class.new(ActiveRest::Model){ properties :address, :addresses, :goodness, :length, :tags }
    @address_class = Class.new(ActiveRest::Model)
    @tag_class = Class.new(ActiveRest::Model)
  end

  it "should leave hashes unmolested even in the presence of a matching class" do
    model = @test_model_class.new({'length'=>10,
                                   'goodness'=>"superb",
                                   'address' => {
                                     'street' => '100 main st',
                                     'zip' => '11111'
                                   }
                                 })
    model.address.should be_instance_of(Hash)
  end

  it "should leave arrays unmolested even in the presence of a matching class" do
    model = @test_model_class.new({'length'=>10,
                                   'goodness'=>"superb",
                                   'tags' => ['to-read', 'denver']
                                 })

    model.tags.should be_instance_of(Array)
    model.tags.first.should be_instance_of(String)
    model.tags.last.should be_instance_of(String)
  end

  it "should leave arrays of hashes unmolested even in the presence of a matching class" do
    model = @test_model_class.new({'length'=>10,
                                   'goodness'=>"superb",
                                   'addresses' => [{
                                                     'street' => '100 main st',
                                                     'zip' => '11111'
                                                   }]
                                 })

    model.addresses.should be_instance_of(Array)
    model.addresses.first.should be_instance_of(Hash)
    model.addresses.last.should be_instance_of(Hash)
  end

end

