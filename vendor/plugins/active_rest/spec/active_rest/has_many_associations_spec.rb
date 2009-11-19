require 'pathname'
require Pathname(__FILE__).dirname + "../spec_helper"
require "active_rest/has_many_associations"
require "json"

module ActiveRest::HasManyAssociations
  describe AssociationCollection, "instantiation" do
    class TestModel < ActiveRest::Model
    end

    it "should be successful with just URI and member's class" do
      lambda {
        AssociationCollection.new("http://example.com/test_models", TestModel)
      }.should_not raise_error
    end

    it "should be successful with just URI, member's class and items" do
      lambda {
        AssociationCollection.new("http://example.com/test_models", TestModel,
                                  [TestModel.new('location'=>'denver')])
      }.should_not raise_error
    end

    it "should be successful with just URI, member's class and items as attribute hashes" do
      lambda {
        AssociationCollection.new("http://example.com/test_models", TestModel,
                                  [{'location'=>'denver'}])
      }.should_not raise_error
    end

    it "should convert items hashes into models" do
      collection = AssociationCollection.new("http://example.com/test_models", TestModel,
                                        [{'location'=>'denver'}])
      collection.first.should be_instance_of(TestModel)
    end

  end

  describe AssociationCollection, "(empty)" do
    class TestModel < ActiveRest::Model
    end

    before do
      @empty_collection = AssociationCollection.new("href://example.com/foos", TestModel, [])
    end

    it "should return true from #empty" do
      @empty_collection.empty?.should be_true
    end

    it "should return 0 from #size" do
      @empty_collection.size.should be_zero
    end

    it "should not yield during #each" do
      yield_count = 0
      lambda {
        @empty_collection.each { |an_item| yield_count += 1 }
      }.should_not change{yield_count}

    end

    it "should be enumerable" do
      @empty_collection.should be_kind_of(Enumerable)
    end

    it 'should return true from #populated?' do
      @empty_collection.populated?.should be_true
    end

    it 'should return nil from #first' do
      @empty_collection.first.should be_nil
    end

    it 'should return nil from #last' do
      @empty_collection.last.should be_nil
    end
  end

  describe AssociationCollection, "(non-empty)" do
    class TestModel < ActiveRest::Model
    end

    before do
      @collection = AssociationCollection.new("href://example.com/foos", TestModel,
                                                    [TestModel.new('location'=>'denver'),
                                                     TestModel.new('location'=>'boulder')])
    end

    it "should return false from #empty" do
      @collection.empty?.should be_false
    end

    it "should return 2 from #size" do
      @collection.size.should == 2
    end

    it "should yield both test models during #each" do
      things = []
      lambda {
        @collection.each { |an_item| things << an_item.location }
      }.should change{things.uniq.size}.by(2)

    end

    it "should be enumerable" do
      @collection.should be_kind_of(Enumerable)
    end

    it 'should return true from #populated?' do
      @collection.populated?.should be_true
    end

    it 'should return first item from #first' do
      @collection.first.should_not be_nil
      @collection.first.location.should == 'denver'
    end

    it 'should return last item from #last' do
      @collection.last.should_not be_nil
      @collection.last.location.should == 'boulder'
    end

  end

  describe AssociationCollection, "automatic population" do
    class TestModel < ActiveRest::Model
      properties :location
    end

    before do
      @collection = AssociationCollection.new("http://example.com/foos", TestModel)
    end

    it 'should return false from #populated? before population' do
      @collection.populated?.should be_false
    end

    it "should populate itself on demand" do
      response = stub(:code => '200',
                      :[] => 'application/vnd.absolute-performance.sysshep+json',
                      :body => JSON({'foos' => {
                                        'href' => 'http://example.com/foos',
                                        'items' =>
                                        [{'location' => 'denver'},
                                         {'location' => 'boulder'}]
                                      }
                                    }))


      ActiveRest::Model.http.
        expects(:get).
        with('http://example.com/foos',
             has_entry(:accept, 'application/vnd.absolute-performance.sysshep+json')).
        returns(response)

      @collection.items.should be_kind_of(Array)
      @collection.items.should have(2).items

      @collection.items.first.should be_instance_of(TestModel)
      @collection.items.first.location.should == 'denver'

      @collection.items.last.should be_instance_of(TestModel)
      @collection.items.last.location.should == 'boulder'
    end

    it "should fail loudly on non-SSJ documents" do
      response = stub(:code => '200',
                      :[] => 'text/plain',
                      :body => "this is a test")


      ActiveRest::Model.http.
        expects(:get).
        with('http://example.com/foos',
             has_entry(:accept, 'application/vnd.absolute-performance.sysshep+json')).
        returns(response)

      lambda {
        @collection.items
      }.should raise_error(ArgumentError,
                           "Only application/vnd.absolute-performance.sysshep+json representations are supported")
    end
  end
end

describe ActiveRest::Model, "has_many association" do
  class TestModelA < ActiveRest::Model
    properties :location
  end
  class TestModelB < ActiveRest::Model
    properties :length, :goodness, :test_model_as
    has_many :test_model_as
  end

  before do
    @model = TestModelB.new({'length' => 10,
                              'goodness' => "superb",
                              'test_model_as' => {
                                'href' => "http://example.com/test_model_as",
                                'items' =>
                                [{'href' => "http://example.com/test_model_as/1",
                                   'location' => 'Boulder'
                                 }]
                              }
                            })
  end

  it "should convert to a model object if an appropriate class is available" do
    @model.test_model_as.should be_instance_of(ActiveRest::HasManyAssociations::AssociationCollection)
    @model.test_model_as.first.should be_instance_of(TestModelA)
  end

  it "should know the URI of the collection" do
    @model.test_model_as.uri.should == "http://example.com/test_model_as"
  end

  it "should populated the models with the attributes" do
    @model.test_model_as.first.location.should == 'Boulder'
  end

  it "should should return same object for subsequent calls" do
    @model.test_model_as.first.should equal(@model.test_model_as.first)
  end
end

describe ActiveRest::Model, "has_many association with explicit class" do
  class TestModelA < ActiveRest::Model
    properties :location
  end
  class TestModelB < ActiveRest::Model
    properties :length, :goodness, :foos
    has_many :foos, :class_name=>'TestModelA'
  end

  before do
    @model = TestModelB.new({'length' => 10,
                              'goodness' => "superb",
                              'foos' => {
                                'href' => "http://example.com/test_model_as",
                                'items' =>
                                [{'href' => "http://example.com/test_model_as/1",
                                   'location' => 'Boulder'
                                 }]
                              }
                            })
  end

  it "should convert to a model object if an appropriate class is available" do
    @model.foos.should be_instance_of(ActiveRest::HasManyAssociations::AssociationCollection)
    @model.foos.first.should be_instance_of(TestModelA)
  end

  it "should know the URI of the collection" do
    @model.foos.uri.should == "http://example.com/test_model_as"
  end

  it "should populated the models with the attributes" do
    @model.foos.first.location.should == 'Boulder'
  end

  it "should should return same object for subsequent calls" do
    @model.foos.first.should equal(@model.foos.first)
  end
end
