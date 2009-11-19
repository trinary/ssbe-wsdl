require 'pathname'
require Pathname(__FILE__).dirname + '../spec_helper'

require 'active_rest/abstract_transmuter'

describe ActiveRest::AbstractTransmuter, '.mime_type' do
  before do
    @t_class = Class.new(ActiveRest::AbstractTransmuter)
  end   

  it 'should allow handled mime_type to be declared' do
    @t_class.instance_eval do 
      mime_type 'application/prs.absoluteperformance.test'
    end
  end
end

describe ActiveRest::AbstractTransmuter do
  before do
    @t_class = Class.new(ActiveRest::AbstractTransmuter) do 
      mime_type 'application/prs.absoluteperformance.test'
    end
  end   

  it 'should provide class attribute containing the handled mime_type' do
    @t_class.mime_type.should == 'application/prs.absoluteperformance.test'
  end 

  it 'should provide instance attribute containing the handled mime_type' do
    @t_class.new.mime_type.should == 'application/prs.absoluteperformance.test'
  end 
  
  it 'should provide class attribute containing a content type pattern for the handled mime type' do
    @t_class.content_type_pattern.to_s.should == '(?i-mx:(?:^|\s)application\/prs\.absoluteperformance\.test(?:[;\s]|$))'
  end  
end 
