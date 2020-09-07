require 'rails_admin/config/fields/base'

module RailsAdmin
  module Config
    module Fields
      module Types
        class TreeSelect < RailsAdmin::Config::Fields::Base
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :partial do
            :form_tree_select
          end

          register_instance_option(:collection) do
            []
          end

          register_instance_option(:association_key) do
            ""
          end
=begin
          def render_tree(data, form)
            data.map do |node_data|
              if node_data[:is_leaf]
                index = SecureRandom.hex
                association_object = value.select { |o| o.send(association_key).to_s == node_data[:value].to_s }[0]
                if association_object
                  %Q{
                    <li>
                      <input type='hidden' name="#{form.object_name}[#{self.name}_attributes][#{index}][id]" value="#{association_object.id}" />
                      <input type="hidden" class="ra-input-destroy" name="#{form.object_name}[#{self.name}_attributes][#{index}][_destroy]" value="0" />
                      <input type='checkbox' class='ra-select-item' checked="checked" name="#{form.object_name}[#{self.name}_attributes][#{index}][#{self.association_key}]" value='#{node_data[:value]}' data-name='#{node_data[:name]}' />#{node_data[:name]}
                    </li>
                  }
                else
                  %Q{
                    <li>
                      <input type='checkbox' class='ra-select-item' name="#{form.object_name}[#{self.name}_attributes][#{index}][#{self.association_key}]" value='#{node_data[:value]}' data-name='#{node_data[:name]}'/>#{node_data[:name]}
                    </li>
                  }
                end
              else
                nodes_html = render_tree(node_data[:value], form)
                %Q{
                    <li>
                      <input type="checkbox"/><span><i class="icon-plus-sign"></i>#{node_data[:name]}</span>
                      <ul>
                        #{nodes_html}
                      </ul>
                    </li>
                }
              end
            end.join
          end
=end

          def render_tree(data, form)
            data.map do |node_data|
              if node_data[:is_leaf]
                index = SecureRandom.hex
                association_object = value.select { |o| o.send(association_key).to_s == node_data[:value].to_s }[0]
                if association_object
                  @select_items += %Q{
                    <div class="ra-select-item-wrap" data-id="#{node_data[:data_id]}">
                      <input type="hidden" name="#{form.object_name}[#{self.name}_attributes][#{index}][id]" value="#{association_object.id}" />
                      <input type="hidden" class="ra-input-destroy" name="#{form.object_name}[#{self.name}_attributes][#{index}][_destroy]" value="0" />
                      <input type="checkbox" id="#{node_data[:value]}" class="ra-select-item" checked="checked" name="#{form.object_name}[#{self.name}_attributes][#{index}][#{self.association_key}]" value="#{node_data[:value]}" data-name="#{node_data[:name]}" />
                      <label for="#{node_data[:value]}">#{node_data[:name]}</label>
                    </div>
                  }
                else
                  @select_items += %Q{
                    <div class="ra-select-item-wrap" data-id="#{node_data[:data_id]}">
                      <input type="checkbox" id="#{node_data[:value]}" class='ra-select-item' name="#{form.object_name}[#{self.name}_attributes][#{index}][#{self.association_key}]" value='#{node_data[:value]}' data-name='#{node_data[:name]}'/>
                      <label for="#{node_data[:value]}">#{node_data[:name]}</label>
                    </div>
                  }
                end
                ""
              else
                nodes_html = render_tree(node_data[:value], form)
                %Q{
                    <li>
                      <input type="checkbox" value="#{node_data[:data_id]}"/><span data-id=>#{node_data[:name]}</span>
                      <ul>
                        #{nodes_html}
                      </ul>
                    </li>
                }
              end
            end.join
          end

          def formatted_render_tree
=begin
            datas = [
            { :name => "c", :data_id => "1", :value => [
                { :name => "d1", :data_id => "1-1", :value => [
                  { :name => "u2", :data_id => "1-1", :value => 2, :is_leaf => true }
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
            @select_items = ""
            form = bindings[:form]
            %Q{ <ul> #{render_tree(self.collection, form)} </ul>}.html_safe
          end

          def get_select_items
            @select_items.html_safe
          end
=begin
          def formatted_show_value
            (bindings[:controller].render_to_string :partial => "rails_admin/main/field_readonly/table_edit", :locals => { :field => self, :form => bindings[:form] }).html_safe
          end
=end
        end
      end
    end
  end
end

