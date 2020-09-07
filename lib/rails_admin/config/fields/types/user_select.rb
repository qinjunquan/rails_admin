require 'rails_admin/config/fields/base'

module RailsAdmin
  module Config
    module Fields
      module Types
        class UserSelect < RailsAdmin::Config::Fields::Base
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :partial do
            :form_user_select
          end

          register_instance_option(:collection) do
            []
          end

          register_instance_option(:association_key) do
            ""
          end

          register_instance_option(:show_method) do
            ""
          end

          def render_tree(data, form)
            data.map do |node_data|
              if node_data[:is_leaf]
                index = SecureRandom.hex
                association_object = value.select { |o| o.send(association_key).to_s == node_data[:value].to_s }[0]
                if association_object
                  @selected_items += %Q{
                    <div class="ra-user-#{node_data[:value]}" >
                      <input class="ra-user-input" name="#{form.object_name}[#{self.name}_attributes][#{node_data[:value]}][id]" value="#{association_object.id}" />
                      <input class="ra-user-destroy" name="#{form.object_name}[#{self.name}_attributes][#{node_data[:value]}][_destroy]" value="0" />
                    </div>
                  }
                  @json_selected_items << { :id=> node_data[:value], :name => node_data[:name], :model => form.object_name, :field => self.name, :field_key => self.association_key }
                end
                @select_items += %Q{
                  <div class="ra-user-#{node_data[:value]} ra-user-wrap" data-id="#{node_data[:data_id]}">
                    <input type="checkbox" id="#{node_data[:value]}" class='ra-user-input' data-inputName="#{form.object_name}[#{self.name}_attributes][#{node_data[:value]}][#{self.association_key}]" data-name='#{node_data[:name]}' value='#{node_data[:value]}'/>
                    <label for="#{node_data[:value]}">#{node_data[:name]}</label>
                  </div>
                }
                @json_items << { :id=> node_data[:value], :name => node_data[:name], :model => form.object_name, :field => self.name, :field_key => self.association_key }
                ""
              else
                nodes_html = render_tree(node_data[:value], form)
                %Q{
                    <li data-field="#{name}">
                      <span data-id="#{node_data[:data_id]}">#{node_data[:name]}</span>
                      <ul>
                        #{nodes_html}
                      </ul>
                    </li>
                }
              end
            end.join
          end

          def formatted_data
=begin
            datas = [
            { :name => "c", :dataId => "1", :value => [
                { :name => "d1", :dataId => "1-1", :value => [
                  { :name => "u2", :dataId => "1-1", :value => 2, :is_leaf => true }
                ]},
                { :name => "d2", :dataId => "1-2", :value => [] },
                { :name => "u1", :dataId => "1", :value => 1, :is_leaf => true }
              ]
            },
            { :name => "c1", :dataId => "2-1", :value => [
                { :name => "d3", :dataId => "2-3", :value => [
                  { :name => "u3", :dataId => "2-3", :value => 3, :is_leaf => true }
                ]},
                { :name => "d4", :dataId => "2-4", :value => [] },
                { :name => "u4", :dataId => "2", :value => 4, :is_leaf => true }
              ]
            }
            ]
=end
            form = bindings[:form]
            %Q{ <ul> #{render_tree(self.collection, form)} </ul>}
          end

          def init_format_data
            @select_items = ""
            @json_items = []
            @selected_items = ""
            @json_selected_items = []
            @tree_items = formatted_data
          end

          def select_users
            @select_items.html_safe
          end

          def selected_form_fields
            @selected_items.html_safe
          end

          def tree_dropdown
            @tree_items.html_safe
          end

          def selected_users
            (@selected_items || "").html_safe
          end

          def json_users
            @json_items.to_json.html_safe
             #[{:id => 7, :name => "Ruby", :model => "announcement", :field => "announcement_notified_users", :field_key => "user_id"}].to_json.html_safe
          end

          def json_selected_users
            @json_selected_items.to_json.html_safe
            #[{:id => 7, :name => "Ruby", :model => "announcement", :field => "announcement_notified_users", :field_key => "user_id"}].to_json.html_safe
          end

          def formatted_show_value
            value.map{ |item| item.send(show_method).to_s }.join(", ")
          end

        end
      end
    end
  end
end

