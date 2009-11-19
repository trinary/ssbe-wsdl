require 'pathname'
require Pathname(__FILE__).dirname + '../spec_helper'

require 'active_rest/ssj_transmuter'

describe ActiveRest::SsjTransmuter do
  it 'should be instantiatable' do
    ActiveRest::SsjTransmuter.new.should be_instance_of(ActiveRest::SsjTransmuter)
  end 
  
  it 'should have correct mime_type' do
    ActiveRest::SsjTransmuter.new.mime_type.should == 'application/vnd.absolute-performance.sysshep+json'
  end 

  it 'should have correct mime_type at class level' do
    ActiveRest::SsjTransmuter.mime_type.should == 'application/vnd.absolute-performance.sysshep+json'
  end
  
  it 'should be registered with ActiveRest::Model' do 
    ActiveRest::Model.transmuters.should include(ActiveRest::SsjTransmuter)
  end
  
  it 'should correct content-type matcher' do
    ActiveRest::SsjTransmuter.content_type_pattern.should == %r{(?:^|\s)application/x\-sysshep\+json|application/vnd\.absolute\-performance\.sysshep\+json(?:[;\s]|$)}i
  end 
end

describe ActiveRest::SsjTransmuter, '#unmarshal (atomic)' do
  before do
    @transmuter = ActiveRest::SsjTransmuter.new
    
    @ssj_doc = JSON('href' => "http://example.com/test_models/3",
                    'id' => "eafsda-aer-aer-aserasd",
                    '_type' => 'TestModel',
                    'length' => 42,
                    'goodness' => nil)
  end

  it 'should convert SSJ doc into a of properties hashes' do
    @transmuter.unmarshal(@ssj_doc).should be_kind_of(Hash)
  end 
  
  it 'should include all attribute present in document' do
    @transmuter.unmarshal(@ssj_doc).should have_key('href')
    @transmuter.unmarshal(@ssj_doc).should have_key('id')
    @transmuter.unmarshal(@ssj_doc).should have_key('_type')
    @transmuter.unmarshal(@ssj_doc).should have_key('length')
    @transmuter.unmarshal(@ssj_doc).should have_key('goodness')
  end 
  
  it 'should have attribute values from document' do
    @transmuter.unmarshal(@ssj_doc)['href'].should == "http://example.com/test_models/3"
    @transmuter.unmarshal(@ssj_doc)['id'].should == "eafsda-aer-aer-aserasd"
    @transmuter.unmarshal(@ssj_doc)['_type'].should == 'TestModel'
    @transmuter.unmarshal(@ssj_doc)['goodness'].should == nil
    @transmuter.unmarshal(@ssj_doc)['length'].should == 42
  end 
end 


describe ActiveRest::SsjTransmuter, '#unmarshal (collections)' do
  before do
    @transmuter = ActiveRest::SsjTransmuter.new
    @ssj_doc = JSON('href' => "http://example.com/test_models",
                               'items' =>
                               [{'href' => "http://example.com/test_models/3",
                                  'id' => "eafsda-aer-aer-aserasd",
                                  '_type' => 'TestModel',
                                  'length' => 42,
                                  'goodness' => "perfect"},
                                {'href' => "http://example.com/test_models/24",
                                  'id' => "eafsda-aer-aer-23af32c",
                                  '_type' => 'TestModel',
                                  'length' => 13,
                                  'goodness' => nil}])
  end

  it 'should convert SSJ collection doc into array containing one item for each of the items' do
    @transmuter.unmarshal(@ssj_doc).should be_kind_of(Array)
    @transmuter.unmarshal(@ssj_doc).size.should == 2
  end 

  2.times do |i|
    it "item #{i} should be a properties hash" do 
      @transmuter.unmarshal(@ssj_doc)[i].should be_kind_of(Hash)
    end

    it "item #{i} should include all attribute present in document" do
      @transmuter.unmarshal(@ssj_doc)[i].should have_key('href')
      @transmuter.unmarshal(@ssj_doc)[i].should have_key('id')
      @transmuter.unmarshal(@ssj_doc)[i].should have_key('_type')
      @transmuter.unmarshal(@ssj_doc)[i].should have_key('length')
      @transmuter.unmarshal(@ssj_doc)[i].should have_key('goodness')
    end 
  end
end 

describe ActiveRest::SsjTransmuter, '#marshal() (atomic)' do
  before do
    @transmuter = ActiveRest::SsjTransmuter.new
    @props = {'href' => "http://example.com/test_models/24",
      'id' => "eafsda-aer-aer-23af32c",
      '_type' => 'TestModel',
      'length' => 18,
      'goodness' => nil}
  end
  
  it 'should produce a valid Json document' do
    JSON.parse(@transmuter.marshal(@props))
  end 
  
  it 'should be equivalent to props hash' do
    JSON.parse(@transmuter.marshal(@props)).should == @props
  end 
end 
