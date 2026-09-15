# frozen_string_literal: true

module Dev
  class SessionsController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :ensure_dev_browser_login_allowed!

    def index
      users = User.includes(:roles).order(:last_name, :first_name, :email)
      query = params[:q].to_s.strip

      if query.present?
        pattern = "%#{User.sanitize_sql_like(query)}%"
        users = users.where(
          'users.email LIKE :q OR users.uniqname LIKE :q OR users.uid LIKE :q OR users.display_name LIKE :q OR users.first_name LIKE :q OR users.last_name LIKE :q',
          q: pattern
        )
      end

      @query = query
      @users = users.limit(50)
    end

    def create
      user = find_user
      unless user
        redirect_to dev_sessions_path(q: params[:q].presence || params[:login]),
                    alert: 'No matching local user was found.'
        return
      end

      sign_out(current_user) if user_signed_in?
      sign_in(user)

      redirect_to after_sign_in_path_for(user),
                  notice: "Dev browser login: signed in as #{user.email}."
    end

    private

    def ensure_dev_browser_login_allowed!
      return if DevBrowserLogin.allowed?(request)

      render 'errors/not_found', status: :not_found, layout: 'application'
    end

    def find_user
      if params[:user_id].present?
        return User.find_by(id: params[:user_id])
      end

      login = params[:login].to_s.strip
      return if login.blank?

      User.find_by(email: login) || User.find_by(uniqname: login) || User.find_by(uid: login)
    end
  end
end
