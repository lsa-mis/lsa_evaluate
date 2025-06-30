class UsersController < ApplicationController
  def lookup
    query = params[:q].to_s.strip
    users = User.where('first_name LIKE :q OR last_name LIKE :q OR email LIKE :q OR uid LIKE :q', q: "%#{query}%").limit(10)
    render json: users.map { |u| { id: u.id, name: "#{u.first_name} #{u.last_name} (#{u.email})", uid: u.uid } }
  end
end
