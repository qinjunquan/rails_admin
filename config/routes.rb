RailsAdmin::Engine.routes.draw do
  controller 'main' do
    RailsAdmin::Config::Actions.all(:root).each { |action| match "/#{action.route_fragment}", action: action.action_name, as: action.action_name, via: action.http_methods }
    match "/reports/:kind", action: :report, via: ['get', 'post']
    match "/jobs/:kind", action: :job, via: ['get', 'post']
    match "/jobs/:kind/:id", action: :job, via: 'get'
    scope ':model_name' do
      RailsAdmin::Config::Actions.all(:collection).each { |action| match "/#{action.route_fragment}", action: action.action_name, as: action.action_name, via: action.http_methods }
      post '/bulk_action', action: :bulk_action, as: 'bulk_action'
      scope ':id' do
        RailsAdmin::Config::Actions.all(:member).each { |action| match "/#{action.route_fragment}", action: action.action_name, as: action.action_name, via: action.http_methods }
      end
    end
  end
end
