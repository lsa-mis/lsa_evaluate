# app/controllers/containers_controller.rb
class ContainersController < ApplicationController
  before_action :set_container, only: %i[show edit update destroy]
  before_action :authorize_container, only: %i[edit update destroy]

  def index
    @containers = policy_scope(Container)
  end

  def show
    @assignments = @container.assignments.includes(:user, :role)
    @assignment = @container.assignments.build
  end

  def new
    @container = Container.new
  end

  def edit; end

  def create
    @container = Container.new(container_params)
    authorize @container, :create?
    @container.creator = current_user

    if @container.save
      respond_to do |format|
        format.html { redirect_to containers_path, notice: 'Collection was successfully created.' }
        format.turbo_stream { redirect_to containers_path, notice: 'Collection was successfully created.' }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace('container_form', partial: 'containers/form', locals: { container: @container }), status: :unprocessable_entity
        }
      end
    end
  end

  def update
    authorize @container, :update?

    if @container.update(container_params)
      respond_to do |format|
        format.html { redirect_to containers_path, notice: 'Collection was successfully updated.' }
        format.turbo_stream { redirect_to containers_path, notice: 'Collection was successfully updated.' }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace('container_form', partial: 'containers/form', locals: { container: @container }), status: :unprocessable_entity
        }
      end
    end
  end

  def destroy
    if @container.destroy
      respond_to do |format|
        format.turbo_stream { redirect_to containers_path, notice: I18n.t('notices.container.destroyed') }
        format.html { redirect_to containers_path, notice: I18n.t('notices.container.destroyed') }
      end
    else
      respond_to do |format|
        format.turbo_stream { redirect_to containers_path, alert: @container.errors.full_messages.to_sentence }
        format.html { redirect_to containers_path, alert: @container.errors.full_messages.to_sentence }
      end
    end
  end

  def admin_content
    render 'admin_content'
  end

  def lookup_user
    @users = User.where('uid LIKE ?', "%#{params[:uid]}%").limit(10)
    render json: @users.map { |user| { uid: user.uid, display_name: user.display_name, display_name_and_uid: user.display_name_and_uid } }
  end

  private

  def authorize_container
    authorize @container
  end

  def set_container
    @container = Container.find(params[:id])
  end

  def container_params
    params.require(:container).permit(:name, :description, :notes, :department_id, :visibility_id,
                                      assignments_attributes: %i[id user_id role_id _destroy])
  end
end
