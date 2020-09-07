module RailsAdmin
  module Config
    module Actions
      class Print < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :member do
          true
        end

        register_instance_option :route_fragment do
          'print'
        end

        register_instance_option :breadcrumb_parent do
          [:index, bindings[:abstract_model]]
        end

        register_instance_option :controller do
          proc do
            respond_to do |format|
              format.html { render @action.template_name, layout: 'rails_admin/print' }
            end
          end
        end
      end
    end
  end
end
