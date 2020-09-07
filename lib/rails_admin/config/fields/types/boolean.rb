#encoding: utf-8
module RailsAdmin
  module Config
    module Fields
      module Types
        class Boolean < RailsAdmin::Config::Fields::Base
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :view_helper do
            :check_box
          end

          register_instance_option :pretty_value do
            case value
            when nil
              "-"
            when false
              "否"
            when true
              "是"
            end.html_safe
          end

          register_instance_option :export_value do
            value.inspect
          end

          # Accessor for field's help text displayed below input field.
          def generic_help
            ''
          end

          def formatted_show_value
            case value
            when nil
              "-"
            when false
              "否"
            when true
              "是"
            end.html_safe
          end

          def formatted_list_value
            case value
            when nil
              "-"
            when false
              "否"
            when true
              "是"
            end.html_safe
          end

        end
      end
    end
  end
end
