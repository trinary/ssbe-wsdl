require "active_rest/model"

module ActiveRest
  module HasManyAssociations
    class AssociationCollection
      include Enumerable

      attr_reader :uri, :member_class, :items

      def initialize(uri, member_class, items=nil)
        @uri = uri
        @member_class = member_class
        @items = interpret_items(items) if items
      end

      def empty?
        items.empty?
      end

      def size
        items.size
      end

      def each(&block)
        items.each(&block)
      end

      def populated?
        not @items.nil?
      end

      def items
        @items ||=
          begin
            resp = ActiveRest::Model.http.get(uri, :accept => 'application/vnd.absolute-performance.sysshep+json')
            raise(ArgumentError,
                  "Only application/vnd.absolute-performance.sysshep+json representations are supported") unless
              resp['Content-Type'] =~ %r{(\s|^)application/vnd\.absolute\-performance\.sysshep\+json([;\s]|$)}
            # we have a response we can work with
            doc = JSON.parse(resp.body)

            interpret_items(doc[doc.keys.first]['items'])
          end
      end

      def first
        items.first
      end

      def last
        items.last
      end

      protected
      def interpret_items(an_items_array)
        an_items_array.map do |an_item|
          an_item.kind_of?(@member_class) ? an_item : @member_class.new(an_item)
        end
      end
    end

    module ClassMethods
      def has_many(association_name, options={})
        associated_class = (options[:class_name] ||
                            association_name.to_s.singularize.camelize).constantize
        association_name = association_name.to_sym
        association_var_name = "@associated_#{association_name}"

        define_method(association_name) do
          instance_variable_get(association_var_name) ||
            instance_variable_set(association_var_name,
                                  AssociationCollection.new(properties[association_name]['href'],
                                                            associated_class,
                                                            properties[association_name]['items']))
        end
      end
    end

    # Hook module inclusion to setup class methods
    def self.included(another)
      another.extend(ClassMethods)
    end

  end
end

ActiveRest::Model.send(:include, ActiveRest::HasManyAssociations)
