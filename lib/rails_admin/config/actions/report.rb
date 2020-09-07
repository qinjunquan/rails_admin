module RailsAdmin
  module Config
    module Actions
      class Report < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection do
          true
        end

        register_instance_option :breadcrumb_parent do
          [:dashboard]
        end

        register_instance_option :controller do
          proc do
            @report_config = RailsAdmin::Config::Report.find(params[:kind].camelcase)
            @results = @report_config.results(params[:search] || {})

            respond_to do |format|
              format.html do
                render "rails_admin/main/reports/#{@report_config.template_name}", layout: "rails_admin/application"
              end

              format.xls do
                output = CSV.generate do |csv|
                  field_names = @report_config.get_fields || @report_config.get_fields_groups.map { |data| data[:fields] }.flatten
                  headers = field_names.map { |field_name| I18n.t("admin.reports.#{params[:kind]}.header.#{field_name}") }
                  csv << headers
                  @results.each do |result|
                    csv << field_names.map { |field_name| result[field_name] }
                  end
                end
                send_data Excelinator.csv_to_xls(output),
                          type: "text/csv; charset=UTF-8; header=present",
                          disposition: "attachment; filename=#{params[:kind]}_#{DateTime.now.strftime("%Y-%m-%d_%Hh%Mm%S")}.xls"
              end
            end

          end
        end
      end
    end
  end
end
