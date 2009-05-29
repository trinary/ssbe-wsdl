ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  map.root :controller => 'ssbe', :action => 'invocation'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
