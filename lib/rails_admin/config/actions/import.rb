module RailsAdmin
  module Config
    module Actions
      class Import < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :collection do
          true
        end

        register_instance_option :breadcrumb_parent do
          [:dashboard]
        end

        register_instance_option :controller do
          proc do
            if request.post?
              job = RaJob.create(:name => "RaImport")
              formated_params = {
                                  :model_class => @abstract_model.to_s.constantize,
                                  :special_values => @model_config.import.get_special_values_block.call(self).stringify_keys!,
                                  :uniq_record_by => @model_config.import.get_uniq_record_by
                                }.merge(params).stringify_keys!
              job.set_params!(formated_params)
              job.save
              job.start!(Rails.env != "development")
              redirect_to "/admin/jobs/ra_import/#{job.id}"
            else
              render @action.template_name
            end
          end
        end
      end
    end
  end
end
