class CorrectionEntriesController < ApplicationController
  helper CorrectionsHelper
  before_action :authenticate_user!
  before_action :load_metric
  before_action :load_measurement

  def edit
    @value = @measurement.value
    @secondary = @measurement.value_secondary
  end

  def update
    error = ::Measurements::BatchCreate.check(@metric, params[:value], params[:value_secondary])
    if error
      @error = error
      @value = params[:value]
      @secondary = params[:value_secondary]
      render :edit, status: :unprocessable_content
      return
    end

    @measurement.update!(
      value: ::Measurements::BatchCreate.parse(params[:value]),
      value_secondary: @metric.blood_pressure? ? ::Measurements::BatchCreate.parse(params[:value_secondary]) : nil
    )
    redirect_to correction_path(@metric.key), notice: "已改这条记录"
  end

  def destroy
    @measurement.destroy!
    redirect_to correction_path(@metric.key), notice: "已删除这次记录"
  end

  private

  def load_metric
    @metric = Metrics::Catalog.find(params[:correction_metric])
    redirect_to corrections_path, alert: "没有这项指标" unless @metric
  end

  def load_measurement
    return if performed?

    @measurement = current_user.measurements.find_by(id: params[:id], metric_type: @metric.key)
    redirect_to(@metric ? correction_path(@metric.key) : corrections_path, alert: "只能修改自己的记录") unless @measurement
  end
end
