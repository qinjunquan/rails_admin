require 'rails_admin/config/sections/base'

module RailsAdmin
  module Config
    module Sections
      # Configuration of the list view
      class List < RailsAdmin::Config::Sections::Base
        # Number of items listed per page
        register_instance_option :items_per_page do
          RailsAdmin::Config.default_items_per_page
        end

        register_instance_option :sort_by do
          parent.abstract_model.primary_key
        end

        register_instance_option :sort_reverse? do
          true # By default show latest first
        end

        register_instance_option :scopes do
          []
        end

        register_instance_option :default_filter do
          ""
        end

        def filter_scoped(&block)
          @filter_scoped_lambda = block
        end

        def filter_scoped_lambda
          @filter_scoped_lambda
        end

        def filter(filter_name, &block)
          @filters ||= {}
          @filters[filter_name.to_s] = block
        end

        def filters
          @filters ||= {}
        end

        def search_fields(*cols)
          @searchable_fields = cols.map(&:to_s)
        end

        def searchable_field?(field_name)
          @searchable_fields ||= []
          (@abstract_model.model.columns.map(&:name) + ["formatted_id"]).include?(field_name.to_s) && @searchable_fields.include?(field_name.to_s)
        end

        def list_kind(col)
          @kind = col.to_s
        end

        def index_kind
          @kind
        end

        def bulk_edit(action_name, &block)
          @bulk_edit_actions ||= {}
          @bulk_edit_actions[action_name.to_s] = block
        end

        def bulk_edit_block_for(action_name)
          @bulk_edit_actions[action_name]
        end

        def bulk_edit_actions
          @bulk_edit_actions ||= {}
        end
      end
    end
  end
end
