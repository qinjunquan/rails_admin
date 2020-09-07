module RailsAdmin
  module Config
    module Actions
      class Job < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection do
          true
        end

        register_instance_option :breadcrumb_parent do
          [:dashboard]
        end

        register_instance_option :controller do
          proc do
            @job_config = RailsAdmin::Config::Job.find(params[:kind].camelcase)
            if request.post?
              job = RaJob.create(:name => @job_config.class_name)
              job.set_params!(params["search"])
              job.start!
              redirect_to "/admin/jobs/#{@job_config.class_name.underscore}/#{job.id}"
            elsif params[:id].present?
              @job = RaJob.find(params[:id])
              render "rails_admin/main/jobs/show", layout: "rails_admin/application"
            else
              render "rails_admin/main/jobs/new", layout: "rails_admin/application"
            end
          end
        end
      end
    end
  end
end
