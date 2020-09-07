require "iconv"
module RailsAdmin
  module Config
    module Actions
      class Index < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :route_fragment do
          ''
        end

        register_instance_option :breadcrumb_parent do
          parent_model = bindings[:abstract_model].try(:config).try(:parent)
          if am = parent_model && RailsAdmin.config(parent_model).try(:abstract_model)
            [:index, am]
          else
            [:dashboard]
          end
        end

        def common_scoped(&block)
          @common_scoped_block = block
        end

        def common_scoped_block
          @common_scoped_block
        end

        register_instance_option :controller do
          proc do
            params[:all] = true if params[:format] == "xls"
            @objects ||= list_entries

            # default scoped
            index_config = RailsAdmin::Config::Actions.find(:index)
            if index_config.common_scoped_block.present?
              @objects = index_config.common_scoped_block.call(self, @objects)
            end

            # list scoped
            unless @model_config.list.scopes.empty?
              if params[:scope].blank?
                unless @model_config.list.scopes.first.nil?
                  @objects = @objects.send(@model_config.list.scopes.first)
                end
              elsif @model_config.list.scopes.collect(&:to_s).include?(params[:scope])
                @objects = @objects.send(params[:scope].to_sym)
              end
            end

            # filter scoped
            if params[:filter].present?
              @objects = @model_config.list.filters[params[:filter].to_s].call(self, @objects)
              @selected_filter = params[:filter].to_s
            elsif @model_config.list.default_filter.present?
              @selected_filter = @model_config.list.default_filter.to_s
              @objects = @model_config.list.filters[@selected_filter].call(self, @objects)
            elsif @model_config.list.filter_scoped_lambda.present?
              @objects = @model_config.list.filter_scoped_lambda.call(self, @objects)
            end

            # Search
            @objects_before_search = @objects # Using for RailsAdmin::Config::Fields::Base#search_input_html
            params[:search] ||= {}
            params[:search] = params[:search].select { |k, v| v.is_a?(Hash) ? v.values.reject { |vv| vv.blank? }.present? : v.present? }
            if params[:search].present?
              column_and_type_map = @abstract_model.to_s.constantize.columns.inject({}) { |hash, c| hash[c.name.to_s] = c.type; hash }
              params[:search].each do |column, value|
                case column_and_type_map[column]
                when :integer, :boolean
                  @objects = @objects.where(column => value)
                when :text, :string
                  @objects = @objects.where("#{column} LIKE ?", "%#{value}%")
                when :date, :datetime
                  begin
                    from = value[:from].blank? ? 50.year.ago : Time.parse(value[:from]).strftime("%Y-%m-%d")
                    to = value[:to].blank? ? Time.now + 50.year : Time.parse(value[:to]).strftime("%Y-%m-%d")
                    @objects = @objects.where("#{column} >= ? AND #{column} <= ?", from, to)
                  rescue
                  end
                end
                if column.to_s == "formatted_id"
                  ids = @abstract_model.to_s.constantize.select("id, created_at").select { |o| o.formatted_id =~ Regexp.new(value) }.map(&:id)
                  @objects = @objects.where(:id => ids)
                end
              end
            end

            if @model_config.export.fields.present?
              @schema ||= {"methods"=>[], "only"=> @model_config.export.fields.map(&:name) }.symbolize
              params[:send_data] = true
            end

            respond_to do |format|

              format.html do
                render @action.template_name, status: (flash[:error].present? ? :not_found : 200)
              end

              format.json do
                output = if params[:compact]
                  primary_key_method = @association ? @association.associated_primary_key : @model_config.abstract_model.primary_key
                  label_method = @model_config.object_label_method
                  @objects.collect { |o| {id: o.send(primary_key_method).to_s, label: o.send(label_method).to_s} }
                else
                  @objects.to_json(@schema)
                end
                if params[:send_data]
                  send_data output, filename: "#{params[:model_name]}_#{DateTime.now.strftime("%Y-%m-%d_%Hh%Mm%S")}.json"
                else
                  render json: output, root: false
                end
              end

              format.xml do
                output = @objects.to_xml(@schema)
                if params[:send_data]
                  send_data output, filename: "#{params[:model_name]}_#{DateTime.now.strftime("%Y-%m-%d_%Hh%Mm%S")}.xml"
                else
                  render xml: output
                end
              end

              format.xls do
                header, encoding, output = CSVConverter.new(@objects, @schema).to_csv({ "encoding_to"=>"UTF-8", "generator"=>{"col_sep"=>","} })
                if params[:send_data]
                  send_data Excelinator.csv_to_xls(output),
                            type: "text/csv; charset=UTF-8; #{"header=present" if header}",
                            disposition: "attachment; filename=#{params[:model_name]}_#{DateTime.now.strftime("%Y-%m-%d_%Hh%Mm%S")}.xls"
                else
                  render text: output
                end
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
