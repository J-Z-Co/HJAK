class CorrectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_metric, only: :show

  def index
  end

  def show
    @measurements = current_user.measurements.where(metric_type: @metric.key).order(recorded_on: :desc, recorded_at: :desc)
  end

  private

  def load_metric
    @metric = Metrics::Catalog.find(params[:metric])
    redirect_to corrections_path, alert: "没有这项指标" unless @metric
  end
end
