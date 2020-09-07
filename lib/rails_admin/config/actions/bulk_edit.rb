module RailsAdmin
  module Config
    module Actions
      class BulkEdit < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:post, :put]
        end

        register_instance_option :controller do
          proc do
            @objects = list_entries(@model_config, :destroy)
            @model_config.list.bulk_edit_block_for(params[:bulk_action_type].to_s).call(self, params, @objects)
            redirect_to back_or_index
          end
        end

        register_instance_option :authorization_key do
          :bulk_edit
        end

        register_instance_option :bulkable? do
          true
        end

        register_instance_option :visible? do
          true
        end
      end
    end
  end
end
