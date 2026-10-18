class MeasurementsController < ApplicationController
  before_action :authenticate_user!

  def new
    @recorded_on = Time.zone.today
    @idempotency_key = SecureRandom.uuid
    @rows = ::Measurements::Row.build(current_user, on: @recorded_on)
  end

  def create
    result = ::Measurements::BatchCreate.call(
      user: current_user,
      recorded_on: measurement_params[:recorded_on],
      idempotency_key: measurement_params[:idempotency_key],
      rows: measurement_params[:measurements]
    )

    if result.errors.any?
      @recorded_on = measurement_params[:recorded_on]
      @idempotency_key = measurement_params[:idempotency_key]
      @base_error = result.errors[:base]
      @rows = ::Measurements::Row.build(
        current_user,
        errors: result.errors,
        submitted: measurement_params[:measurements] || {}
      )
      render :new, status: :unprocessable_entity
    elsif result.already_saved
      redirect_to root_path, notice: "这次记录已经保存"
    elsif result.saved.empty?
      redirect_to root_path, notice: "没有填写要保存的指标"
    else
      names = result.saved.map { |measurement| Metrics::Catalog.find(measurement.metric_type).label }
      redirect_to root_path, notice: "已保存#{names.join("、")}"
    end
  end

  def destroy
    measurement = Measurement.find_by(id: params[:id])
    if measurement.nil? || measurement.user_id != current_user.id
      redirect_to root_path, alert: "只能删除自己的记录"
      return
    end

    label = Metrics::Catalog.find(measurement.metric_type)&.label || "记录"
    measurement.destroy!
    redirect_to root_path, notice: "已删除#{label}"
  end

  private

  def measurement_params
    nested = Metrics::Catalog.all.map(&:key).index_with { [ :value, :value_secondary ] }
    params.permit(:idempotency_key, :recorded_on, measurements: nested)
  end
end
