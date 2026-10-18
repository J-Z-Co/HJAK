class SuggestionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @suggestions = listed_suggestions
    @suggestion = Suggestion.new
    @open_id = params[:open].to_i
  end

  def create
    parent = parent_from_params
    @suggestion = current_user.suggestions.build(body: suggestion_params[:body], parent: parent)
    if @suggestion.save
      open_id = parent.id if parent && params[:list_open] == "1"
      redirect_to suggestions_path(open: open_id), notice: "已提交"
    else
      @suggestions = listed_suggestions
      @open_id = parent&.id
      @reply_parent_id = parent&.id
      render :index, status: :unprocessable_content
    end
  end

  def vote
    suggestion = Suggestion.find(params[:id])
    column = { "reasonable" => :reasonable_count, "wrong" => :wrong_count }[params[:choice].to_s]
    return head :unprocessable_content if column.nil?

    Suggestion.increment_counter(column, suggestion.id)
    suggestion.reload
    render json: { reasonable_count: suggestion.reasonable_count, wrong_count: suggestion.wrong_count }
  end

  def destroy
    current_user.suggestions.find(params[:id]).destroy!
    redirect_to suggestions_path, notice: "已删除"
  end

  private

  def listed_suggestions
    Suggestion.roots.includes(:user, replies: :user).order(created_at: :desc)
  end

  def suggestion_params
    params.require(:suggestion).permit(:body)
  end

  def parent_from_params
    return if params[:parent_id].blank?

    Suggestion.roots.find(params[:parent_id])
  end
end
