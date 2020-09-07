module RailsAdmin
  module Config
    class Report
      class << self
        def reset
          @@reports = []
        end

        def all
          @@reports
        end

        def find(key)
          @@reports.select { |report| report.class_name == key }[0]
        end
      end

      def initialize(entity, &block)
        @entity = entity
        raise "Should be like this Report::XXX" if @entity.to_s !~ /::/
        @class_name = @entity.to_s.split("::")[1]
        @fields_groups = []
        @filters = []
        instance_eval(&block) if block
        @@reports ||= []
        @@reports << self
      end

      def fields(*options)
        @fields = options
      end

      def get_fields
        @fields
      end

      def fields_group(options)
        @fields_groups << options
      end

      def get_fields_groups
        @fields_groups
      end

      def class_name
        @class_name
      end

      def filter(name, type = :string, inline_block = nil, &block)
        @filters << { :field_name => name, :type => type, :block => inline_block || block }
      end

      def get_filters
        @filters
      end

      def results(search)
        @entity.results(search)
      end

      def template_name
        if @fields_groups.present?
          "multipart_header"
        else
          "single_header"
        end
      end
    end
  end
end
