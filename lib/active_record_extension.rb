# encoding: utf-8
module ActiveRecordExtension
  extend ActiveSupport::Concern

  # add your instance methods here
  def identify_name
    @identify_name ||= begin
                         if self.respond_to?(:name)
                           self.try(:name)
                         elsif self.respond_to?(:title)
                           self.try(:title)
                         else
                           'NONE'
                         end
                       end
  end

  # add your static(class) methods here
  module ClassMethods
    # Usage:
    # has_formatted_id                    # => '00001'
    # has_formatted_id :timestamp => true # => 'S2014010100001'
    # has_formatted_id :prefix => 'C'     # => 'C00001'
    # has_formatted_id :prefix => true    # => 'S00001' (when ClassName is SaleOrder)
    # has_formatted_id :length => 3       # => '001'
    def has_formatted_id(options={})
      define_method :formatted_id do
        return '保存后自动生成' if self.new_record?
        # basic id
        t_id = (id || self.class.last.id + 1) rescue 1
        # timestamp
        timestamp = options[:timestamp].present? ? (self.created_at || Time.now rescue Time.now).strftime("%Y%m%d") : ''
        # prefix
        if options[:prefix].present?
          prefix = options[:prefix] == true ? self.class.name[0] : options[:prefix]
        else
          prefix = ''
        end
        # length
        length = options[:length].to_i > 0 ? options[:length].to_i : 5
        # formatted_id output
        "#{prefix}#{timestamp}#{t_id.to_s.rjust(length, "0")}"
      end
    end
  end
end

# include the extension
ActiveRecord::Base.send(:include, ActiveRecordExtension)

class ActiveRecord::Base
  def all_attrs_blank(attrs)
    attrs.values.reject(&:blank?).empty?
  end
end
