require "active_rest/model"

module ActiveRest
  module HasOneAssociations
    module ClassMethods
      def has_one(association_name, options={})
        associated_class = (options[:class_name] || association_name.to_s.camelize).constantize
        association_name = association_name.to_sym
        association_var_name = :"@associated_#{association_name}"

        define_method(association_name) do
          instance_variable_get(association_var_name) ||
            instance_variable_set(association_var_name,
                                  associated_class.new(properties[association_name]))
        end
      end
    end

    # Hook module inclusion to setup class methods
    def self.included(another)
      another.extend(ClassMethods)
    end

    protected
    def associations
      @associations ||= Hash.new
    end
  end
end

ActiveRest::Model.send(:include, ActiveRest::HasOneAssociations)
