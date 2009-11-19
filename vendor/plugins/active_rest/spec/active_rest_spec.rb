require 'pathname'
require Pathname(__FILE__).dirname + "spec_helper"

require 'active_rest'

describe ActiveRest do
  it 'should throw recreated resource accessor if logger is changed' do
    l = stub('logger')
    ActiveRest.logger = l
    ActiveRest.logger.should == l
  end

  it 'should expose trace logging flag' do
    ActiveRest.should respond_to(:trace_logging?)
  end 
  
  it 'should allow trace logging to be enabled' do
    ActiveRest.enable_trace_logging
    ActiveRest.should be_trace_logging
  end 
end
