require File.dirname(__FILE__) + '/../test_helper'
require 'ssbe_controller'

class SsbeController; def rescue_action(e) raise e end; end

class SsbeControllerApiTest < Test::Unit::TestCase
  def setup
    @controller = SsbeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
end
