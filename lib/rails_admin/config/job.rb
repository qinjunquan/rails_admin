module RailsAdmin
  module Config
    class Job
      class << self
        def reset
          @@jobs = []
        end

        def all
          @@jobs
        end

        def find(key)
          @@jobs.select { |job| job.class_name == key }[0]
        end
      end

      def initialize(entity, &block)
        raise "Should be like this Job::XXX" if entity.to_s !~ /::/
        @class_name = entity.to_s.split("::")[1]
        @fields = []
        instance_eval(&block) if block
        @@jobs ||= []
        @@jobs << self
      end

      def class_name
        @class_name
      end

      def field(name, type = :string, inline_block = nil, &block)
        @fields << { :field_name => name, :type => type, :block => inline_block || block }
      end

      def get_fields
        @fields
      end
    end
  end
end
