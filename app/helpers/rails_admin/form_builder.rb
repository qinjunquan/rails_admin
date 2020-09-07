module RailsAdmin
  class FormBuilder < ::ActionView::Helpers::FormBuilder
    include ::NestedForm::BuilderMixin

    def attr_input(attr)
      begin
        @all_fields ||= []
        if @all_fields.empty?
          options = {
            action: @object.new_record? ? "create" : "update",
            model_config: @template.instance_variable_get(:@model_config),
            nested_in: false
          }
          @all_fields = visible_groups(options[:model_config], generator_action(options[:action], options[:nested_in]))[0].with(form: self, object: @object, view: @template, controller: @template.controller).visible_fields
        end
        fieldset = @all_fields.select { |f| f.name == attr }[0]

        if @template.instance_variable_get(:@readonly_form) || @object.try(:is_readonly)
          readonly_field_wrapper_for(fieldset, false)
        else
          field_wrapper_for(fieldset, false).html_safe
        end
      rescue => e
        %Q{#{attr}: <a href="#" onclick="$(this).find('div').toggle()">#{e} <div style="display:none;">#{e.backtrace.join("\n")}</div></a> }.html_safe
      end
    end

    def generate(options = {})
      without_field_error_proc_added_div do
        options.reverse_merge!(
          action: @template.controller.params[:action],
          model_config: @template.instance_variable_get(:@model_config),
          nested_in: false
        )

        if options[:action] == :show
          options[:action] = :update
          options[:nested_in] = true
        end

        object_infos +
        visible_groups(options[:model_config], generator_action(options[:action], options[:nested_in])).collect do |fieldset|
          fieldset_for fieldset, options[:nested_in]
        end.join.html_safe +
        (options[:nested_in] ? '' : @template.render(partial: 'rails_admin/main/submit_buttons'))
      end
    end

    def fieldset_for(fieldset, nested_in)
      if (fields = fieldset.with(form: self, object: @object, view: @template, controller: @template.controller).visible_fields).length > 0
        @template.content_tag :fieldset do
          contents = []
          contents << @template.content_tag(:legend, %(<i class="icon-chevron-#{(fieldset.active? ? 'down' : 'right')}"></i> #{fieldset.label}).html_safe, style: "#{fieldset.name == :default ? 'display:none' : ''}")
          contents << @template.content_tag(:p, fieldset.help) if fieldset.help.present?
          if @template.instance_variable_get(:@readonly_form)
            contents << fields.collect { |field| readonly_field_wrapper_for(field, nested_in) }.join
          else
            contents << fields.collect { |field| field_wrapper_for(field, nested_in) }.join
          end
          contents.join.html_safe
        end
      end
    end

    def field_wrapper_for(field, nested_in)
      if field.label
        # do not show nested field if the target is the origin
        unless nested_field_association?(field, nested_in)
          @template.content_tag(:div, class: "control-group #{field.type_css_class} #{field.css_class} #{'error' if field.errors.present?}", id: "#{dom_id(field)}_field") do
            %Q{<label class="control-label" for="#{field.method_name}">#{required_tag(field.method_name)} #{field.label}</label>}.html_safe +
            (field.nested_form ? field_for(field) : input_for(field))
          end
        end
      else
        field.nested_form ? field_for(field) : input_for(field)
      end
    end

    def readonly_field_wrapper_for(field, nested_in)
      if field.label
        unless nested_field_association?(field, nested_in)
          @template.content_tag(:div, class: "control-group #{field.type_css_class} #{field.css_class} #{'error' if field.errors.present?}", id: "#{dom_id(field)}_field") do
            label(field.method_name, field.label, class: 'control-label') +
            %Q{<div class="controls"><div class="cms-readonly-wrap">#{field.formatted_show_value}</span></div></div>}.html_safe
          end
        end
      else
        field.pretty_value.to_s
      end
    end

    def required_tag(field_name)
      @object.class.validators_on(field_name).present? ? "<span class='ra-required-tag'>*</span>" : ""
    end

    def input_for(field)
      @template.content_tag(:div, class: 'controls') do
        field_for(field) +
        errors_for(field) +
        help_for(field)
      end
    end

    def errors_for(field)
      field.errors.present? ? @template.content_tag(:span, "#{field.label} #{field.errors.to_sentence}", class: 'help-inline') : ''.html_safe
    end

    def help_for(field)
      ""#field.help.present? ? @template.content_tag(:p, field.help, class: 'help-block') : ''.html_safe
    end

    def field_for(field)
      if field.read_only?
        field.pretty_value.to_s.html_safe
      else
        #field.render
        field_html = field.render
        if field_html.to_s.match("type=\"text\"").present? && [:double, :float].include?(field.type)
          field_html = field_html.gsub("type=\"text\"","step=\"0.0001\" type=\"number\"")
        end
        field_html.html_safe
      end
    end

    def field_for_table_edit(field_base, field_config, associate_object, field_input_name)
      field_config[:type] ||= "string"
      tmp_column = associate_object.class.columns.select { |c| c.name == field_config[:field_name].to_s }[0]
      tmp_property = RailsAdmin::Adapters::ActiveRecord::Property.new(tmp_column, associate_object)
      tmp_field = RailsAdmin::Config::Fields::Types.load(field_config[:type]).new(field_base, field_config[:field_name], tmp_property)
      tmp_field = tmp_field.with({ :form => self, :object => associate_object, :view => @template })
      tmp_field.instance_eval(&field_config[:block]) if field_config[:block].present?
      tmp_html_attributes = tmp_field.html_attributes.merge!(:name => field_input_name)
      tmp_field.register_instance_option :html_attributes do
        tmp_html_attributes
      end

      main_object = self.object
      self.object = associate_object
      html = field_config[:readonly] ? tmp_field.formatted_show_value : self.field_for(tmp_field)
      html = ""
      if field_config[:readonly]
        html = tmp_field.formatted_show_value
      else
        if self.object.class.to_s == "Asset"
          html = self.field_for(tmp_field)
        else
          html = (self.object.class.validators_on(field_config[:field_name]).present? ? "<span class='ra-required-tag'>*</span>" : "") + self.field_for(tmp_field)
        end
      end
      if html.to_s.match("maxlength=\"4\"").present?
        html = html.gsub("maxlength=\"4\"","")
        #html = html.gsub("type=\"text\"","type=\"number\"")
      end

      if html.to_s.match("type=\"text\"").present? && [:double, :float].include?(tmp_column.type)
        html = html.gsub("type=\"text\"","step=\"0.0001\" type=\"number\"")
      end

      if associate_object.errors.messages.keys().include?(field_config[:field_name])
        html += %Q{<span class="help-inline s-help-inline">#{associate_object.errors.messages[field_config[:field_name]][0]}</span>}.html_safe
      end
      self.object = main_object
      html.to_s.html_safe
    end

    def object_infos
      model_config = RailsAdmin.config(object)
      model_label = model_config.label
      object_label = if object.new_record?
        I18n.t('admin.form.new_model', name: model_label)
      else
        object.send(model_config.object_label_method).presence || "#{model_config.label} ##{object.id}"
      end
      %(<span style="display:none" class="object-infos" data-model-label="#{model_label}" data-object-label="#{CGI.escapeHTML(object_label.to_s)}"></span>).html_safe
    end

    def jquery_namespace(field)
      %(#{'#modal ' if @template.controller.params[:modal]}##{dom_id(field)}_field)
    end

    def dom_id(field)
      (@dom_id ||= {})[field.name] ||=
        [
          @object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, '_').sub(/_$/, ''),
          options[:index],
          field.method_name
        ].reject(&:blank?).join('_')
    end

    def dom_name(field)
      (@dom_name ||= {})[field.name] ||= %(#{@object_name}#{options[:index] && "[#{options[:index]}]"}[#{field.method_name}]#{field.is_a?(Config::Fields::Association) && field.multiple? ? '[]' : ''})
    end

    def app
      @template.controller
    end

  protected

    def generator_action(action, nested)
      if nested
        action = :nested
      elsif @template.request.format == 'text/javascript'
        action = :modal
      end

      action
    end

    def visible_groups(model_config, action)
      model_config.send(action).with(
        form: self,
        object: @object,
        view: @template,
        controller: @template.controller
      ).visible_groups
    end

    def without_field_error_proc_added_div
      default_field_error_proc = ::ActionView::Base.field_error_proc
      begin
        ::ActionView::Base.field_error_proc = proc { |html_tag, instance| html_tag }
        yield
      ensure
        ::ActionView::Base.field_error_proc = default_field_error_proc
      end
    end

  private

    def nested_field_association?(field, nested_in)
      field.inverse_of.presence && nested_in.presence && field.inverse_of == nested_in.name &&
        (@template.instance_variable_get(:@model_config).abstract_model == field.associated_model_config.abstract_model ||
         field.name == nested_in.inverse_of)
    end
  end
end
