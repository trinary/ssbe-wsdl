require 'action_controller/resources'
require 'action_controller/base'

module ActionController
  class Base
    def default_template_name_with_partitioned_collection_handling(action_name =
                                                                   self.action_name)
      if matches = /^(index|create|new)_by_/.match(action_name)
        action_name = matches[1]
      end
      default_template_name_without_partitioned_collection_handling(action_name)
    end
    alias_method_chain :default_template_name, :partitioned_collection_handling
  end

  module Resources
    class Resource
      attr_reader :collection_path_prefix, :collection_paths, :new_paths

      def initialize_with_collection_partitioning_support(entities, options)
        initialize_without_collection_partitioning_support(entities, options)

        figure_collection_paths
      end
      alias_method_chain :initialize, :collection_partitioning_support

      def base_path
        @base_path ||= "#{path_prefix}/#{plural}"
      end
      alias path base_path

      def member_path
        @member_path ||= "#{base_path}/:id"
      end

      def nesting_path_prefix
        @nesting_path_prefix ||= "#{base_path}/:#{singular}_id"
      end

      def new_paths
        @new_paths ||= collection_paths.map do |a_path_info|
                         returning a_path_info.clone do |a_path_info|
                           a_path_info[:path] += "/new"
                         end
                       end.reject { |elt| elt[:no_create] }
      end

      protected

      def figure_collection_paths
        parents = options[:partition_collection_by]
        @collection_paths = if parents.nil?
                              p = returning Hash.new do |path|
                                path[:path] = base_path
                                path[:name_prefix] = name_prefix if name_prefix
                              end
                              [p]
                            else
                              parents = interpret_partition_collection_by_option(parents)

                              returning Array.new do |collection_paths|
                                parents.each do |a_parent, options|
                                  collection_paths << returning(options.clone) do |path|
                                    parent_route = ActionController::Routing::Routes.named_routes[a_parent]
                                    path[:path] = parent_route.segments.inject("") { |str,s| str << s.to_s }.gsub(%r(^/), '').gsub(%r(:id), ":#{a_parent}_id") + "#{plural}"
                                    path[:partition_criterion] = a_parent
                                  end
                                end
                              end
                            end
      end

      def interpret_partition_collection_by_option(parents)
        case parents
        when Symbol
          {parents=>{}}
        when Array
          returning Hash.new do |parents_hash|
            parents.each do |a_parent|
              case a_parent
              when Symbol, String
                parents_hash[a_parent.to_sym] = { }
              when Array
                parents_hash[a_parent[0].to_sym] = a_parent[1]
              when Hash
                parent_name = a_parent.keys.first
                parents_hash[parent_name.to_sym] = a_parent[parent_name]
              end
            end
          end
        end
      end

    end

    protected

    def map_default_collection_actions(map, resource)
      resource.collection_paths.each do |a_collection|
        base_route_name = "#{a_collection[:name_prefix]}#{resource.plural}"
        index_action_options = action_options_for("index", resource).clone
        if a_collection[:partition_criterion]
          index_action_options[:action] += "_by_#{a_collection[:partition_criterion]}"
          base_route_name += "_by_#{a_collection[:partition_criterion]}"
        end

        map.named_route(base_route_name, a_collection[:path], index_action_options)
        map.named_route("formatted_#{base_route_name}", "#{a_collection[:path]}.:format", index_action_options)

        unless a_collection[:no_create]
          create_action_options = action_options_for("create", resource)
          if a_collection[:partition_criterion]
            create_action_options[:action] += "_by_#{a_collection[:partition_criterion]}"
          end
          map.connect(a_collection[:path], create_action_options)
          map.connect("#{a_collection[:path]}.:format", create_action_options)
        end
      end
    end

    def map_new_actions(map, resource)
      resource.new_paths.each do |a_new_resource|
        resource.new_methods.each do |method, actions|
          actions.each do |action|
            action_options = action_options_for(action, resource, method)
            if action == :new
              base_route_name = "new_#{a_new_resource[:name_prefix]}#{resource.singular}"
              criterion_suffix = nil
              if a_new_resource[:partition_criterion]
                action_options[:action] += "_by_#{a_new_resource[:partition_criterion]}"
                criterion_suffix = "_by_#{a_new_resource[:partition_criterion]}"
                base_route_name += criterion_suffix
              end

              # See http://dev.rubyonrails.org/ticket/8251
              map.named_route(base_route_name,
                              a_new_resource[:path], action_options)
              map.named_route("formatted_new_#{base_route_name}",
                              "#{a_new_resource[:path]}.:format", action_options)
            else
              # See http://dev.rubyonrails.org/ticket/8251
              map.named_route("#{action}_new_#{base_route_name}",
                              "#{a_new_resource[:path]}/#{action}", action_options)
              map.named_route("formatted_#{action}_new_#{base_route_name}",
                              "#{a_new_resource[:path]}/#{action}.:format", action_options)
            end
          end
        end
      end
    end
  end
end


