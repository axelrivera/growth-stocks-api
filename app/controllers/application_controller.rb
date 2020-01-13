class ApplicationController < ActionController::API
  before_action :validate_auth_token

  def validate_auth_token
    return unless Rails.env.production?
    head 403 if ENV['AUTH_TOKEN'].blank?

    auth_header = request.env['HTTP_AUTHORIZATION']
    if auth_header && auth_header.split(' ').length == 2 
      components = auth_header.split(' ')
      auth_token = components[1] if components[0] == 'Basic'
    end

    render json: { error: "unauthorized user" }, status: :unauthorized unless auth_token == ENV['AUTH_TOKEN']
  end

end
