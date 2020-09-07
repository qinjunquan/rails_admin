require 'rails_admin/config/sections/base'

module RailsAdmin
  module Config
    module Sections
      class Import < RailsAdmin::Config::Sections::Base
        def fields(*attrs)
          resource_name = @abstract_model.model_name.underscore
          @_field_mapping = {}
          attrs.map(&:to_s).each do |attr|
            t_key = "#{resource_name}.#{attr}"
            t_key = "#{resource_name}.formatted_id" if attr == "id"
            if attr =~ /\./
              nested_resource_name, nested_method = attr.split(".")
              t_key = "#{resource_name}_#{nested_resource_name}.#{nested_method}"
            end
            t_label = I18n.t("activerecord.attributes.#{t_key}")
            raise "Can't found translation for activerecord.attributes.#{t_key}" if t_label =~ /translation missing/
            @_field_mapping[t_label] = attr
          end
        end

        def get_fields
          @_field_mapping.stringify_keys!
        end

        def special_values(&block)
          @_speical_values_block = block
        end

        def get_special_values_block
          @_speical_values_block
        end

        def uniq_record_by(value)
          @_uniq_record_by = value
        end

        def get_uniq_record_by
          @_uniq_record_by.to_s
        end

        def formated_values(&block)
          @_formated_values_block = block
        end

        def get_formated_values_block
          @_formated_values_block
        end
      end
    end
  end
end
