require 'rails_admin/config/fields/base'

module RailsAdmin
  module Config
    module Fields
      module Types
        class TableEdit < RailsAdmin::Config::Fields::Base
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :partial do
            :form_table_edit
          end

          register_instance_option(:fields) do
            []
          end

          def formatted_show_value
            (bindings[:controller].render_to_string :partial => "rails_admin/main/field_readonly/table_edit", :locals => { :field => self, :form => bindings[:form] }).html_safe
          end
        end
      end
    end
  end
end
