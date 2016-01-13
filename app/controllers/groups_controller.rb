class GroupsController < ApplicationController
  respond_to :json, :html

  before_action :find_group, only: [:show, :edit, :update, :destroy]

  before_action only: [:show, :edit, :update, :destroy] do
    @group = Group.find(params[:id])
  end

  before_action only: [:edit, :update, :destroy] do
    render nothing: true, status: :unauthorized unless @group.is_editable_by? current_user
  end

  def index
    @groups = Group.order(created_at: :desc)
                  .paginate(page: params[:page], per_page: 9)
  end

  def new
    @group = Group.new
  end

  def create
    group_data = group_params
    group_data[:user_id] = current_user.id
    @group = Group.new group_data
    if @group.save
      current_user.groups << @group
      current_user.alter_points :other, 3
      redirect_to group_url(@group)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    @group.update!(group_params)
    redirect_to group_url(@group)
  end

  def show
  end

  def destroy
    @group.destroy
    current_user.alter_points :other, -3

    redirect_to groups_url
  end

  # ajax methods

  def ajax_index
    groups = Group.where("name like ?", "%#{params[:q]}%")
    user_groups = current_user.groups.map(&:id)
    new_groups = groups.reject{|n| user_groups.include?(n.id)}
    render json: new_groups.as_json(only: [:id, :name])
  end

  private

  def find_group
    @group = Group.find_by(:id => params[:id])
  end

  def group_params
    params.required(:group).permit(:name, :user_id, :description, :contact_email, :listserv, :meetings).merge(params.permit(:membership_type))
  end

end
