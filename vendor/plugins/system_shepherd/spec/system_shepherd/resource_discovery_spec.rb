require 'pathname'
require Pathname(__FILE__).dirname + '../spec_helper'
require 'system_shepherd/resource_discovery'

describe SystemShepherd, "#resource_discoverer(service_type, resource_name)" do
  before do  
    @http_accessor = mock('http_accessor')
    @resource_descriptor = mock('resource_descriptor')
    
    @sysshep = SystemShepherd.new('http://domain.example/capabilities', :http_accessor => @http_accessor)
    SystemShepherd::ResourceDescriptor.stub!(:new).and_return(@resource_descriptor)
  end
  
  it 'should return a Proc' do
    @sysshep.resource_discoverer('http://domain.example/services/test', 'MyTestResource').should be_instance_of(Proc)
  end 
  
  it 'should create a ResourceDescriptor for type and resource name' do 
    SystemShepherd::ResourceDescriptor.should_receive(:new).with(@sysshep, 'http://domain.example/services/test', 'MyTestResource').
      and_return(@resource_descriptor)
    
    @sysshep.resource_discoverer('http://domain.example/services/test', 'MyTestResource')
  end

  it 'should return resource_descriptor#href when invoked' do
    @resource_descriptor.should_receive(:href).and_return(:marker)
    @sysshep.resource_discoverer('http://domain.example/services/test', 'MyTestResource').call.should == :marker
  end 
end

describe SystemShepherd::ResourceDescriptor, "#href()" do
  before do
    @capabilities = {'items' => [{'service_type' => 'http://domain.example/services/test', 
                                   'href' => 'http://www.example/test_service/descriptor'}]}
    @test_service_descriptor = {'resources' => [{'name' => 'MyTestResource', 
                                                  'href' => 'http://www.example/test_service/test_resource'}]}
    
    @http_accessor = mock('http_accessor')
    @http_accessor.stub!(:get_body).and_return(@capabilities.merge(@test_service_descriptor))
                                            
    @sysshep = SystemShepherd.new('http://domain.example/capabilities', :http_accessor => @http_accessor)

    @resource_descriptor = SystemShepherd::ResourceDescriptor.new(@sysshep, 'http://domain.example/services/test', 'MyTestResource')
  end

  it 'should get the body of the capabilities resource' do
    @http_accessor.should_receive(:get_body).once.with('http://domain.example/capabilities', anything).and_return(@capabilities)
    @resource_descriptor.href
  end 
  
  it 'should get the body for the service descriptor of interest' do
    @http_accessor.should_receive(:get_body).with('http://www.example/test_service/descriptor', anything).and_return(@test_service_descriptor)
    @resource_descriptor.href
  end 
  
  it 'shoudl return the href to the resource of interst' do
    @resource_descriptor.href.should == 'http://www.example/test_service/test_resource'
  end 
end 
