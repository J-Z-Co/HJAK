module Api
  module V1
    class MeasurementsController < BaseController
      # GET /api/v1/measurements/new
      def new
        recorded_on = Time.zone.today
        idempotency_key = SecureRandom.uuid
        rows = ::Measurements::Row.build(current_api_user, on: recorded_on)
        progress = ::Gamification::Progress.for(current_api_user, rows: rows)

        render json: {
          recorded_on: recorded_on.iso8601,
          idempotency_key: idempotency_key,
          rows: rows.map { |row| Api::Serializer.measurement_row(row) },
          progress: Api::Serializer.progress(progress)
        }
      end

      # POST /api/v1/measurements
      # body: { recorded_on:, idempotency_key:, measurements: { weight: { value: "60" }, blood_pressure: { value: "120", value_secondary: "80" } } }
      def create
        result = ::Measurements::BatchCreate.call(
          user: current_api_user,
          recorded_on: params[:recorded_on],
          idempotency_key: params[:idempotency_key],
          rows: params[:measurements]
        )

        if result.errors.any?
          render json: { errors: result.errors }, status: :unprocessable_entity
        elsif result.already_saved
          render json: { notice: "这次记录已经保存", already_saved: true }
        elsif result.saved.empty?
          render json: { notice: "没有填写要保存的指标" }
        else
          names = result.saved.map { |measurement| Metrics::Catalog.find(measurement.metric_type).label }
          ::Nudge.resolve_for!(current_api_user)
          render json: { saved: names, notice: "已保存#{names.join("、")}" }, status: :created
        end
      end

      # DELETE /api/v1/measurements/:id
      def destroy
        measurement = current_api_user.measurements.find_by(id: params[:id])
        return render json: { error: "只能删除自己的记录" }, status: :forbidden unless measurement

        label = Metrics::Catalog.find(measurement.metric_type)&.label || "记录"
        measurement.destroy!
        render json: { notice: "已删除#{label}" }
      end
    end
  end
end
