# frozen_string_literal: true

require 'require_params'

class ApplicationController < ActionController::API
  before_action :authenticate

  protected

  include RequireParams

  DEFAULT_PAGE_SIZE = 10

  def authenticate
    authentication_token = request.headers['Authorization']
    unless authentication_token
      errors = ['Authorization token required']
      render json: { errors: errors }, status: :unauthorized
      return false
    end

    user = UserService.authenticate authentication_token
    unless user
      errors = ['Invalid or expired authentication token']
      render json: { errors: errors }, status: :unauthorized
      return false
    end

    User.current = user
    true
  end

  def paginate(queryset)
    limit = (params[:page_size] || DEFAULT_PAGE_SIZE).to_i
    offset = (params[:page] || 0).to_i * DEFAULT_PAGE_SIZE

    queryset.offset(offset).limit(limit)
  end
end
