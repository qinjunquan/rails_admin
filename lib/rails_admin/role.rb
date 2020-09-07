#encoding:utf-8
module RailsAdmin
  class Role

    class << self
      def config
        @config ||= eval(File.read("#{Rails.root}/config/role.rb")).map { |data| data.stringify_keys }
      end

      def can?(role, kind, resource)
        begin
          resources = can_resources(role, kind)
          resources == [:all] ? true : resources.include?(resource.to_s.downcase)
        rescue
          false
        end
      end

      def can_resources(role, kind)
        begin
          config.map(&:stringify_keys!)
          permissions = config.select { |r| r["role"] == role.to_s }[0]["permissions"]

          return [:all] if permissions.nil?
          permissions.stringify_keys!
          (permissions[kind.to_s].to_a + permissions["all"].to_a).uniq.map(&:to_s).map(&:downcase)
        rescue
          []
        end
      end
    end

  end
end

class ActionController::Base
  before_action :check_permission

  def check_permission
    if params["controller"] == "rails_admin/main" && params["action"] != "dashboard"
      unless RailsAdmin::Role.can?(current_user.role, params[:action], (params[:model_name] || "#{params[:action]}/#{params[:kind]}"))
        flash[:error] = "你没有权限操作'#{I18n.t("activerecord.models.#{params[:model_name]}")}'"
        return redirect_to("/admin")
      end
    end
  end
end
