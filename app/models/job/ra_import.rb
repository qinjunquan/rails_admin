#encoding: utf-8
module Job
  class RaImport
    def self.process(job)
      begin
        job.update_logger("=" * 100)
        job.update_logger("#{Time.now.strftime("%Y-%m-%d-%H:%M:%S")} 执行")
        job.update_logger("=" * 100)
        file = File.open(job.params["file"])
        sheet = Spreadsheet.open(file).worksheet(0)
        @import_config = RailsAdmin::AbstractModel.all.select { |m| m.model_name == job.params["model_class"].to_s }[0].config.import

        sheet_header = sheet.row(0).to_a.map(&:to_s)
        method_index_mapping = {}
        @import_config.get_fields.each do |title, method_name|
          index = sheet_header.index(title.to_s)
          raise "Import: CAN'T FOUND COLUMN #{title}" if index.nil?
          method_index_mapping[method_name] = index
        end

        valid_objects, objects_count = [], sheet.row_count - 1
        formated_rows = @import_config.get_fields.any? { |k, v| v =~ /\./ } ? formated_as_nested_rows(job, sheet, method_index_mapping) : formated_as_normal_rows(sheet, method_index_mapping)
        formated_rows.each_with_index do |row, i|
          job.update_progress(i * 100 / objects_count)
          job.update_logger("#{objects_count}-#{i + 1}: 正在导入\n\t #{row.values.join(", ")} \n\t #{"-" * 100}")

          object = job.params["model_class"].new

          row.each do |m, v|
            object.send("#{m}=", v)
          end

          job.params["special_values"].each { |m, value| object.send("#{m}=", value) }

          if object.valid?
            valid_objects << object
          else
            raise "Can't save #{object.errors.inspect}"
          end
        end

        ActiveRecord::Base.transaction do
          valid_objects.map(&:save)
        end

        job.mark_as_done!
      rescue => e
        job.mark_as_error!
        job.update_logger("出错: #{e.to_s}")
      end
    end

    def self.formated_as_nested_rows(job, sheet, method_index_mapping)
      ##[{
      ##    "id" => 1, "month" => "2014-09",
      ##    "instances_attributes" => [{ "sop_number" => 1 }, { "sop_number" => 2 }]
      ##}]
      formated_rows = []
      sheet.to_a[1..-1].group_by { |row| row[method_index_mapping[job.params["uniq_record_by"]]] }.values.each do |row_arr|
        formated_row = {}
        main_obj_methods, slave_obj_methods = method_index_mapping.select { |k, v| k !~ /\./ && k != job.params["uniq_record_by"] }, method_index_mapping.select { |k, v| k =~ /\./ }
        main_obj_methods.each { |m, index| formated_row[m] = row_arr[0][index] }

        slave_obj_methods.each do |s_m, m_index|
          slave, m = s_m.split(".")
          row_arr.each_with_index do |row, index|
            formated_row[slave] ||= []
            formated_row[slave][index] ||= {}
            formated_row[slave][index][m] = row[m_index]
          end
        end
        formated_rows << formated_row
      end
      formated_row_values(formated_rows)
    end

    def self.formated_as_normal_rows(sheet, method_index_mapping)
      formated_rows = []
      sheet.each_with_index do |row, i|
        next if i == 0
        hash = {}
        method_index_mapping.each do |m, index|
          hash[m] = row[index]
        end
        formated_rows << hash
      end
      formated_row_values(formated_rows)
    end

    def self.formated_row_values(rows, scoped = nil)
      if @import_config.get_formated_values_block.is_a?(Proc)
        rows.each do |row|
          row.each do |m, v|
            if v.is_a?(Array)
              formated_row_values(v, m)
            else
              formated_method_name = scoped ? "#{scoped}.#{m}" : m
              row[m] = @import_config.get_formated_values_block.call(formated_method_name, v)
            end
          end
        end
      end
    end

  end
end
