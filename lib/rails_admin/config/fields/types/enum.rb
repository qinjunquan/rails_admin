require 'rails_admin/config/fields/types/string'

module RailsAdmin
  module Config
    module Fields
      module Types
        class Enum < RailsAdmin::Config::Fields::Base
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :partial do
            :form_enumeration
          end

          register_instance_option :enum_method do
            @enum_method ||= bindings[:object].class.respond_to?("#{name}_enum") || bindings[:object].respond_to?("#{name}_enum") ? "#{name}_enum" : name
          end

          register_instance_option :available_values do
            nil
          end

          register_instance_option :depend_on do
            nil
          end

          register_instance_option :depend_on_method do
            nil
          end

          register_instance_option :autofill_attrs do
            {}
          end

          register_instance_option :autofill_key do
            bindings[:form].dom_id(self)
          end

          register_instance_option :category_key do
            bindings[:form].dom_id(self)
          end

          register_instance_option :search_key do
            nil
          end

          register_instance_option :pretty_value do
            if enum.is_a?(::Hash)
              enum.reject { |k, v| v.to_s != value.to_s }.keys.first.to_s.presence || value.presence || ' - '
            elsif enum.is_a?(::Array) && enum.first.is_a?(::Array)
              enum.detect { |e|e[1].to_s == value.to_s }.try(:first).to_s.presence || value.presence || ' - '
            else
              value.presence || ' - '
            end
          end

          register_instance_option :multiple? do
            properties && [:serialized].include?(properties.type)
          end

          register_instance_option :display_method do
            nil
          end

          register_instance_option :editable do
            false
          end

          def available_values
            @_available_values
          end

          def available_values=(value)
            @_available_values = value
          end

          def enum(collection = nil, &block)
            #跑production ENV，第一次访问show页面之后，会把@_enum赋值为nil, 再去访问edit页面的时候, 不会再调用这个接口，@_enum为nil导致报错
            #development模式下每次访问edit页面都会调用这个接口,因此@_enum非nil不会报错
            enum = collection || block
            @_enum = enum if enum.present?
            @_enum = [] if @_enum.blank?
            @original_enum = @_enum
            @_enum
          end

          def category(collection = nil, &block)
            @_category = collection || block
          end

          def formatted_autofill_attrs
            autofill_attrs_arr = if autofill_attrs.is_a?(Array)
                                  autofill_attrs.map { |attr| [attr, attr] }
                                else
                                  autofill_attrs.to_a
                                end
            autofill_attrs_arr.map do |k, attr|
              if html_attributes[:name].present?
                attr_name = html_attributes[:name].sub("[#{name}]", "[#{attr}]")
              else
                attr_name = bindings[:form].dom_name(self).sub("[#{name}]", "[#{attr}]")
              end
              [k, attr_name]
            end
          end

          def formatted_enum_without_editable(controller = nil)
            if @_enum.is_a?(ActiveRecord::Relation)
              if @_enum.size > 0
                guess_methods = [display_method, "name", "title", "formatted_id"].compact
                guess_methods.map do |attr|
                  if @_enum[0].respond_to?(attr)
                    if depend_on && depend_on_method
                      return @_enum.map { |o| [o.send(attr), o.id, o.send(depend_on_method)] }
                    else
                      return @_enum.map { |o| [o.send(attr), o.id] }
                    end
                  end
                end
                raise "Doesn't find method #{guess_methods.join(',')} in enum"
              else
                []
              end
            elsif @_enum.is_a?(Hash)
              @_enum.to_a
            elsif @_enum.is_a?(Proc)
              @_enum = @_enum.call(controller || bindings[:controller], bindings[:object])
              formatted_enum
            else
              @_enum
            end
          end

          def reset
            @_enum = @original_enum
          end

          def formatted_enum(controller = nil)
            if editable
              formatted_enum_without_editable(controller) + [[formatted_value, formatted_value]]
            else
              formatted_enum_without_editable(controller)
            end
          end

          def formatted_category
            @_category.is_a?(Proc) ? @_category.call : @_category
          end

          def formatted_depend_on
            depend_on.to_s.sub("{class_name}", bindings[:form].object_name.to_s)
          end

          def formatted_list_value(&block)
            if @_list_value.is_a?(Proc)
              @_list_value.call(bindings[:controller], bindings[:object])
            else
              formatted_enum.select { |k, v| v.to_s == formatted_value.presence.to_s }[0][0] rescue formatted_value.presence
            end
          end

          def formatted_show_value
            return @_show_value.call(bindings[:form].app, bindings[:object]) if @_show_value.present? && @_show_value.is_a?(Proc)
            return @_show_value if @_show_value.present?
            formatted_enum.select { |v, k| k.to_s == value.to_s }[0][0] rescue pretty_value.to_s
          end
        end
      end
    end
  end
end
