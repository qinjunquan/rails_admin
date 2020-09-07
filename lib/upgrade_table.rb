require 'active_record/connection_adapters/abstract/schema_definitions'
require 'active_record/connection_adapters/abstract/schema_statements'

module ActiveRecord
  class Migration
    class CommandRecorder
      private

      def invert_add_paperclip_columns(args)
        [:remove_column, [args[0], *::ActiveRecord::ConnectionAdapters::SchemaStatements::QOR_PAPERCLIP_COLUMNS.keys.map {|c| "#{args[1]}_#{c}"}]]
      end

      def invert_add_audit_columns(args)
        [:remove_column, [args[0], :creator_id, :updater_id]]
      end
    end
  end

  module ConnectionAdapters # :nodoc:
    module SchemaStatements

      QOR_PAPERCLIP_COLUMNS = {
        :file_name    => [:string],
        :file_size    => [:integer],
        :coordinates  => [:string, {:limit => 1024}],
        :content_type => [:string],
        :updated_at   => [:datetime]
      }

      def add_paperclip_columns(table_name, attachment)
        QOR_PAPERCLIP_COLUMNS.each do |postfix, options|
          options[1] ||= {}
          add_column table_name, "#{attachment}_#{postfix}", options[0], options[1]
        end
      end

      def add_audit_columns(table_name)
        add_column table_name, "creator_id", :integer
        add_column table_name, "updater_id", :integer
      end

      class SafeTable < Table
        def initialize(table_name, base)
          super(table_name, base)
          @base.create_table(@table_name) unless @base.table_exists?(@table_name)
        end

        def column(column_name, type, options = {})
          return super(column_name, type, options) unless @base.column_exists?(@table_name, column_name)

          if options[:null].nil?
            options[:null] = true
          end

          changed_properties = changed_properties(column_name, options)

          return if changed_properties.empty?
          change(column_name, type, options)
          change_default(column_name, options[:default]) if changed_properties.include?(:default)
          @base.change_column_null(@table_name, column_name, options[:null], options[:default]) if changed_properties.include?(:null)
        end

        def index(column_name, options = {})
          return if index_exists?(column_name, options)
          super
        end

        def rename(column_name, new_column_name)
          return if @base.column_exists?(@table_name, new_column_name)
          return if !@base.column_exists?(@table_name, column_name)
          return super
        end

        def remove(*column_names)
          existed = column_names.select{|column_name| @base.column_exists?(@table_name, column_name) }
          return if existed.empty?

          super(existed)
        end

        def timestamps
          return super unless @base.column_exists?(@table_name, :created_at)
        end

        def paperclip(attachment)
          QOR_PAPERCLIP_COLUMNS.each do |postfix, options|
            options[1] ||= {}
            send options[0], "#{attachment}_#{postfix}", options[1]
          end
        end

        # Adds a column or columns of a specified type
        # ===== Examples
        #  t.string(:goat)
        #  t.string(:goat, :sheep)
        %w( string text integer float decimal datetime timestamp time date binary boolean ).each do |column_type|
          class_eval <<-EOV, __FILE__, __LINE__ + 1
            def #{column_type}(*args)                                          # def string(*args)
              options = args.extract_options!                                  #   options = args.extract_options!
              column_names = args                                              #   column_names = args
                                                                               #
              column_names.each do |name|                                      #   column_names.each do |name|
                column = ColumnDefinition.new(@base, name, '#{column_type}')   #     column = ColumnDefinition.new(@base, name, 'string')
                if options[:limit]                                             #     if options[:limit]
                  column.limit = options[:limit]                               #       column.limit = options[:limit]
                elsif native['#{column_type}'.to_sym].is_a?(Hash)              #     elsif native['string'.to_sym].is_a?(Hash)
                  column.limit = native['#{column_type}'.to_sym][:limit]       #       column.limit = native['string'.to_sym][:limit]
                end                                                            #     end
                column.precision = options[:precision]                         #     column.precision = options[:precision]
                column.scale = options[:scale]                                 #     column.scale = options[:scale]
                column.default = options[:default]                             #     column.default = options[:default]
                column.null = options[:null]                                   #     column.null = options[:null]
                self.column(name, '#{column_type}', options)                   #     self.column(name, column.sql_type, options)
              end                                                              #   end
            end                                                                # end
          EOV
        end

        private
          def changed_properties(column_name, new_options={})
            original_column = @base.columns(@table_name).detect {|c| c.name.to_s == column_name.to_s }

            result = [:default, :limit, :null, :precision, :scale].select do |attr|
              original_value = original_column.send(attr)
              new_value = new_options[attr]
              new_options.has_key?(attr) && new_value.inspect != original_value.inspect
            end

            result
          end

      end

      def upgrade_table(table_name)
        yield SafeTable.new(table_name, self)
      end

      def safe_rename_table(table_name, new_table_name)
        return if table_exists?(new_table_name)
        return if !table_exists?(table_name)
        rename_table(table_name, new_table_name)
      end

      def merge_table_schema(from_table_name, to_table_name)
        st = SafeTable.new(to_table_name, self)
        self.columns(from_table_name).each {|c| st.column(c.name, c.sql_type, {:null => c.null, :limit => c.limit, :default => c.default, :precision => c.precision, :scale => c.scale })}
      end

    end # SchemaStatements
  end # ConnectionAdapters
end # ActiveRecord
