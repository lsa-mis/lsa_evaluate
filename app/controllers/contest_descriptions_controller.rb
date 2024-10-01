class ContestDescriptionsController < ApplicationController
  before_action :set_container
  before_action :set_contest_description, only: %i[show edit update destroy eligibility_rules]

  def index
    @contest_descriptions = ContestDescription.all
  end

  def show; end

  def new
    @contest_description = @container.contest_descriptions.new
  end

  def edit; end

  def create
    @contest_description = @container.contest_descriptions.new(contest_description_params)

    respond_to do |format|
      if @contest_description.save
        format.turbo_stream {
                              redirect_to container_path(@container),
                              notice: I18n.t('notices.contest_description.create')
                            }
        format.html {
                      redirect_to container_path(@container),
                      notice: I18n.t('notices.contest_description.create')
                    }
      else
        format.turbo_stream {
                              render turbo_stream: turbo_stream.replace('contest_description_form',
                              partial: 'contest_descriptions/form',
                              locals: { contest_description: @contest_description }),
                              status: :unprocessable_entity
                            }
        format.html {
                      render :new,
                      status: :unprocessable_entity
                    }
      end
    end
  end

  def update
    respond_to do |format|
      if @contest_description.update(contest_description_params)
        format.turbo_stream {
                              redirect_to container_path(@container),
                              notice: I18n.t('notices.contest_description.updated.')
                            }
        format.html {
                      redirect_to container_path(@container),
                      notice: I18n.t('notices.contest_description.updated.')
                    }
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace('contest_description_form',
          partial: 'contest_descriptions/form',
          locals: { contest_description: @contest_description }),
          status: :unprocessable_entity
        }
        format.html {
          render :edit,
          status: :unprocessable_entity
        }
      end
    end
  end

  def contest_descriptions_for_container
    @contest_descriptions = @container.contest_descriptions
  end

  def destroy
    @contest_description.destroy

    respond_to do |format|
      format.turbo_stream
      format.html {
        redirect_to containers_path,
        notice: I18n.t('notices.contest_description.destroyed')
      }
    end
  end

  def eligibility_rules
    respond_to do |format|
      format.html {
        render partial: 'eligibility_rules',
        locals: { contest_description: @contest_description }
      }
      format.turbo_stream
    end
  end

  private
  def set_container
    @container = Container.find(params[:container_id])
  end

  def set_contest_description
    @contest_description = ContestDescription.find(params[:id])
  end

  def contest_description_params
    params.require(:contest_description).permit(:created_by, :active, :archived,
                                                :eligibility_rules, :name, :notes,
                                                :short_name,
                                                :container_id, :status_id)
  end
end
