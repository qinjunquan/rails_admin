module RailsAdmin::Config::Fields::Types
  class Month < RailsAdmin::Config::Fields::Base
    RailsAdmin::Config::Fields::Types::register(:month, self)

    register_instance_option(:partial) do
      :form_month
    end

    register_instance_option :display_method do
      nil
    end

    def formatted_value
      if display_method
        bindings[:object].send(display_method)
      elsif name =~ /_id$/
        guess_methods = ["name", "title", "formatted_id"].compact
        guess_methods.map do |attr|
          guess_method_name = name.to_s.sub(/_id$/, "_#{attr}")
          return bindings[:object].send(guess_method_name) if bindings[:object].respond_to?(guess_method_name)
        end
        value
      else
        value
      end
    end
  end
end
