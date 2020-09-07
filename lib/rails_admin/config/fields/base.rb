require 'rails_admin/config/proxyable'
require 'rails_admin/config/configurable'
require 'rails_admin/config/hideable'
require 'rails_admin/config/groupable'

module RailsAdmin
  module Config
    module Fields
      class Base
        include RailsAdmin::Config::Proxyable
        include RailsAdmin::Config::Configurable
        include RailsAdmin::Config::Hideable
        include RailsAdmin::Config::Groupable

        attr_reader :name, :properties, :abstract_model
        attr_accessor :defined, :order, :section
        attr_reader :parent, :root

        def initialize(parent, name, properties)
          @parent = parent
          @root = parent.root

          @abstract_model = parent.abstract_model
          @defined = false
          @name = name.to_sym
          @order = 0
          @properties = properties
          @section = parent
        end

        register_instance_option :css_class do
          "#{self.name}_field"
        end

        def type_css_class
          "#{type}_type"
        end

        def virtual?
          properties.blank?
        end

        register_instance_option :column_width do
          nil
        end

        register_instance_option :sortable do
          !virtual? || children_fields.first || false
        end

        register_instance_option :queryable? do
          !virtual?
        end

        register_instance_option :filterable? do
          !!searchable # rubocop:disable DoubleNegation
        end

        register_instance_option :search_operator do
          @search_operator ||= RailsAdmin::Config.default_search_operator
        end

        # serials and dates are reversed in list, which is more natural (last modified items first).
        register_instance_option :sort_reverse? do
          false
        end

        register_instance_option :formatted_value do
          value
        end

        # output for pretty printing (show, list)
        register_instance_option :pretty_value do
          formatted_value.presence || ' - '
        end

        # output for printing in export view (developers beware: no bindings[:view] and no data!)
        register_instance_option :export_value do
          pretty_value
        end

        # Accessor for field's help text displayed below input field.
        register_instance_option :help do
          (@help ||= {})[::I18n.locale] ||= generic_field_help
        end

        register_instance_option :html_attributes do
          {}
        end

        # Accessor for field's label.
        #
        # @see RailsAdmin::AbstractModel.properties
        register_instance_option :label do
          (@label ||= {})[::I18n.locale] ||= abstract_model.model.human_attribute_name name
        end

        register_instance_option :hint do
          (@hint ||= '')
        end

        # Accessor for field's maximum length per database.
        #
        # @see RailsAdmin::AbstractModel.properties
        register_instance_option :length do
          @length ||= properties && properties.length
        end

        # Accessor for field's length restrictions per validations
        #
        register_instance_option :valid_length do
          @valid_length ||= abstract_model.model.validators_on(name).detect { |v| v.kind == :length }.try { |v| v.options } || {}
        end

        register_instance_option :partial do
          :form_field
        end

        # Accessor for whether this is field is mandatory.
        #
        # @see RailsAdmin::AbstractModel.properties
        register_instance_option :required? do
          context = if bindings && bindings[:object]
            bindings[:object].persisted? ? :update : :create
          else
            :nil
          end
          (@required ||= {})[context] ||= !!([name] + children_fields).uniq.detect do |column_name| # rubocop:disable DoubleNegation
            abstract_model.model.validators_on(column_name).detect do |v|
              !v.options[:allow_nil] &&
              [:presence, :numericality, :attachment_presence].include?(v.kind) &&
              (v.options[:on] == context || v.options[:on].blank?)
            end
          end
        end

        # Accessor for whether this is a serial field (aka. primary key, identifier).
        #
        # @see RailsAdmin::AbstractModel.properties
        register_instance_option :serial? do
          properties && properties.serial?
        end

        register_instance_option :view_helper do
          :text_field
        end

        register_instance_option :read_only? do
          !editable?
        end

        # init status in the view
        register_instance_option :active? do
          false
        end

        register_instance_option :visible? do
          returned = true
          (RailsAdmin.config.default_hidden_fields || {}).each do |section, fields|
            if self.section.is_a?("RailsAdmin::Config::Sections::#{section.to_s.camelize}".constantize)
              returned = false if fields.include?(name)
            end
          end
          returned
        end

        # columns mapped (belongs_to, paperclip, etc.). First one is used for searching/sorting by default
        register_instance_option :children_fields do
          []
        end

        register_instance_option :render do
          bindings[:view].render partial: "rails_admin/main/#{partial}", locals: {field: self, form: bindings[:form]}
        end

        def editable?
          !(@properties && @properties.read_only?)
        end

        # Is this an association
        def association?
          kind_of?(RailsAdmin::Config::Fields::Association)
        end

        # Reader for validation errors of the bound object
        def errors
          ([name] + children_fields).uniq.collect do |column_name|
            bindings[:object].errors[column_name]
          end.uniq.flatten
        end

        # Reader whether field is optional.
        #
        # @see RailsAdmin::Config::Fields::Base.register_instance_option :required?
        def optional?
          !required?
        end

        # Inverse accessor whether this field is required.
        #
        # @see RailsAdmin::Config::Fields::Base.register_instance_option :required?
        def optional(state = nil, &block)
          if !state.nil? || block # rubocop:disable NonNilCheck
            required state.nil? ? proc { false == (instance_eval(&block)) } : false == state
          else
            optional?
          end
        end

        # Writer to make field optional.
        #
        # @see RailsAdmin::Config::Fields::Base.optional
        def optional=(state)
          optional(state)
        end

        # Reader for field's type
        def type
          @type ||= self.class.name.to_s.demodulize.underscore.to_sym
        end

        # Reader for field's value
        def value
          bindings[:object].safe_send(name)
        end

        # Reader for nested attributes
        register_instance_option :nested_form do
          false
        end

        # Allowed methods for the field in forms
        register_instance_option :allowed_methods do
          [method_name]
        end

        def generic_help
          (required? ? I18n.translate('admin.form.required') : I18n.translate('admin.form.optional')) + '. '
        end

        def generic_field_help
          model = abstract_model.model_name.underscore
          model_lookup = "admin.help.#{model}.#{name}".to_sym
          translated = I18n.translate(model_lookup, help: generic_help, default: [generic_help])
          (translated.is_a?(Hash) ? translated.to_a.first[1] : translated).html_safe
        end

        def parse_input(params)
          # overriden
        end

        def inverse_of
          nil
        end

        def method_name
          name
        end

        def form_default_value
          (default_value if bindings[:object].new_record? && value.nil?)
        end

        def form_value
          form_default_value.nil? ? formatted_value : form_default_value
        end

        ## Configure value
        def default_value(val = nil)
          @_default_value = val
        end

        def formatted_default_value
          return value if value.present?
          return @_default_value.call(bindings[:form].app, bindings[:object]) if @_default_value.present? && @_default_value.is_a?(Proc)
          return @_default_value if @_default_value.present?
        end

        def list_value(val)
          @_list_value = val
        end

        def formatted_list_value(&block)
          if @_list_value.is_a?(Proc)
            @_list_value.call(bindings[:controller], bindings[:object])
          else
            formatted_value.presence || default_value
          end
        end

        def show_value(val)
          @_show_value = val
        end

        def formatted_show_value
          return @_show_value.call(bindings[:form].app, bindings[:object]) if @_show_value.present? && @_show_value.is_a?(Proc)
          return @_show_value if @_show_value.present?
          return value if value.present?
          "-"
        end

        def search_input_html(controller)
          data = controller.params[:search]
          case self.type
          when :enum
            fake_object = FakeModel.new
            if controller.params[:search]
              controller.params[:search].each do |k, v|
                eval(%{
                    def fake_object.#{k}
                      '#{v}'
                    end
                })
              end
            end
            fake_form = RailsAdmin::FormBuilder.new(:search, fake_object, controller, {})
            self.bindings ||= {}
            self.bindings[:form] = fake_form
            self.bindings[:object] = fake_object
            if controller.params[:action] != "report"
              temp_values = controller.instance_variable_get("@objects_before_search")
              self.available_values = temp_values.present? ? temp_values.limit(10000000).map { |o| o.send(name) } : []
            end

            controller.render(:partial => "rails_admin/main/#{self.partial}", :locals => { :field => self, :form => fake_form })
          when :date, :datetime
            val = controller.params["search"][self.name] rescue ''
            %Q{
              <input value="#{val}" name="search[#{self.name}]" data-datetimepicker="true" data-options='{"datepicker":{"dateFormat":"yy-mm-dd","value":""},"showTime":false}' />
            }
          when :date_to_date
            from_val = data[self.name][:from] rescue ''
            to_val = data[self.name][:to] rescue ''
            %Q{
              <input value="#{from_val}" name="search[#{self.name}][from]" data-datetimepicker="true" data-options='{"datepicker":{"dateFormat":"yy-mm-dd","value":"#{from_val}"},"showTime":false}' />
              #{I18n.t("admin.search.to_sym")}
              <input value="#{to_val}" name="search[#{self.name}][to]" class="ra-end" data-datetimepicker="true" data-options='{"datepicker":{"dateFormat":"yy-mm-dd","value":"#{to_val}"},"showTime":false}' />
            }
          when :month
            val = controller.params["search"][self.name] rescue ''
            %Q{
              <input name="search[#{self.name}]" class="s-month-picker" type="text" value="#{val}"></input>
            }
          when :file_upload
            %Q{ <input name="search[#{self.name}]" type="file"></input> }
          else
            %Q{<input type="text" name="search[#{name}]" value="#{data[name] rescue ''}"/>}
          end
        end

        def inspect
          "#<#{self.class.name}[#{name}] #{
            instance_variables.collect do |v|
              value = instance_variable_get(v)
              if [:@parent, :@root, :@section, :@children_fields_registered,
                  :@associated_model_config, :@group, :@bindings].include? v
                if value.respond_to? :name
                  "#{v}=#{value.name.inspect}"
                else
                  "#{v}=#{value.class.name}"
                end
              else
                "#{v}=#{value.inspect}"
              end
            end.join(", ")
          }>"
        end
      end
    end
  end
end
