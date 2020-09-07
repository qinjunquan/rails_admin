module RailsAdmin::Config::Fields::Types
  class Readonly < RailsAdmin::Config::Fields::Base
    RailsAdmin::Config::Fields::Types::register(:readonly, self)

    register_instance_option(:partial) do
      :form_readonly
    end

    register_instance_option :display_method do
      nil
    end

    register_instance_option :pretty_value do
      value
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
