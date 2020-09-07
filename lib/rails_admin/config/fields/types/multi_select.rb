require 'rails_admin/config/fields/base'

module RailsAdmin
  module Config
    module Fields
      module Types
        class MultiSelect < RailsAdmin::Config::Fields::Base
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :partial do
            :form_multi_select
          end

          register_instance_option(:collection) do
            []
          end

          register_instance_option(:data_url) do
            ""
          end

          register_instance_option(:class_name) do
            ""
          end

          register_instance_option(:value_field) do
            ""
          end

          register_instance_option(:display_field) do
            ""
          end

          register_instance_option(:association_key) do
            ""
          end

          register_instance_option(:show_method) do
            ""
          end

          def format_remote_data(form)
            value.map do |item|
              association_object = self.class_name.classify.constantize.where(self.value_field.to_sym => item.send(association_key)).first
              if association_object
                @_form_items += %Q{
                  <div class="ra-selected-item">
                    <input class="ra-item-input" name="#{form.object_name}[#{self.name}_attributes][#{item.id}][id]" value="#{association_object.id}" />
                    <input class="ra-item-destroy" name="#{form.object_name}[#{self.name}_attributes][#{item.id}][_destroy]" value="0" />
                  </div>
                }
                @_selected_items << { :id => association_object.send(self.value_field), :name => association_object.send(self.display_field) , :model => form.object_name , :field => self.name , :field_key => self.association_key }
              end
            end

          end

          def format_local_data(datas, form)
            datas.map do |item|
              association_object = value.select { |o| o.send(association_key).to_s == item.send(self.value_field).to_s }[0]
              name = item.send(self.display_field).blank? ? "" : item.send(self.display_field)
              if association_object
                @_form_items += %Q{
                  <div class="ra-item-#{item.id}">
                    <input class="ra-item-input" name="#{form.object_name}[#{self.name}_attributes][#{item.id}][id]" value="#{association_object.id}" />
                    <input class="ra-item-destroy" name="#{form.object_name}[#{self.name}_attributes][#{item.id}][_destroy]" value="0" />
                  </div>
                }
                @_selected_items << { :id => item.send(self.value_field), :name => name , :model => form.object_name , :field => self.name , :field_key => self.association_key }
              end
              @_select_items << { :id => item.send(self.value_field), :name => name, :model => form.object_name , :field => self.name , :field_key => self.association_key }
            end
          end

          def is_local_pattern?
            !self.data_url.present?
          end

          def url
            self.data_url
          end

          def init_data
            @_select_items = []
            @_selected_items = []
            @_form_items = ""
            form = bindings[:form]

            if self.data_url.present?
              format_remote_data(form)
            else
              format_local_data(self.collection, form)
            end
          end

          def hidden_form_items
            @_form_items.html_safe
          end

          def local_select_items
            @_select_items.to_json.html_safe
          end

          def selected_items
            @_selected_items.to_json.html_safe
          end

          def formatted_show_value
            value.map{ |item| item.send(show_method).to_s }.join(", ")
          end

        end
      end
    end
  end
end


