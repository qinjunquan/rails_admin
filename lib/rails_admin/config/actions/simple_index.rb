module RailsAdmin
  module Config
    module Actions
      class SimpleIndex < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :route_fragment do
          'simple_index'
        end

        register_instance_option :breadcrumb_parent do
          parent_model = bindings[:abstract_model].try(:config).try(:parent)
          if am = parent_model && RailsAdmin.config(parent_model).try(:abstract_model)
            [:index, am]
          else
            [:dashboard]
          end
        end

        register_instance_option :controller do
          proc do
            @objects ||= list_entries.limit(5)
            respond_to do |format|
              format.html do
                render @action.template_name, layout: "rails_admin/simple_index"
              end
            end

          end
        end

        register_instance_option :link_icon do
          'icon-th-list'
        end
      end
    end
  end
end

