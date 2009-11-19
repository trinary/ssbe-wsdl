require 'pathname'
require Pathname(__FILE__).dirname + "../spec_helper"
require "active_rest/has_one_associations"
require "json"


describe ActiveRest::Model, "has_one association" do
  class TestModelA < ActiveRest::Model
    properties :location
  end
  class TestModelB < ActiveRest::Model
    properties :length, :goodness, :test_model_a
    has_one :test_model_a
  end

  before do
    @model = TestModelB.new({'length' => 10,
                              'goodness' => "superb",
                              'test_model_a' => {
                                'href' => "http://example.com/test_model_as/1",
                                'location' => 'Boulder'
                              }})
  end

  it "should convert to a model object if an appropriate class is available" do
    @model.test_model_a.should be_instance_of(TestModelA)
  end

  it "should should return same object for subsequent calls" do
    @model.test_model_a.should equal(@model.test_model_a)
  end
end

describe ActiveRest::Model, "has_one association with explicit class" do
  class TestModelA < ActiveRest::Model
    properties :location
  end
  class TestModelB < ActiveRest::Model
    properties :length, :goodness, :foo
    has_one :foo, :class_name=>'TestModelA'
  end

  before do
    @model = TestModelB.new({'length' => 10,
                              'goodness' => "superb",
                              'foo' => {
                                'href' => "http://example.com/test_model_as/1",
                                'location' => 'Boulder'
                              }})
  end

  it "should convert to a model object if an appropriate class is available" do
    @model.foo.should be_instance_of(TestModelA)
  end

  it "should should return same object for subsequent calls" do
    @model.foo.should equal(@model.foo)
  end
end
