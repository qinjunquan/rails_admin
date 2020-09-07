require 'rails_admin/config/fields/base'

module RailsAdmin
  module Config
    module Fields
      module Types
        class Hidden < RailsAdmin::Config::Fields::Base
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option(:partial) do
            :form_hidden
          end

          register_instance_option :label do
            false
          end

          def generic_help
            false
          end
        end
      end
    end
  end
end
