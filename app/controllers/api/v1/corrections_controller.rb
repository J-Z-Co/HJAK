module Api
  module V1
    class CorrectionsController < BaseController
      # GET /api/v1/corrections
      def index
        render json: { metrics: Metrics::Catalog.all.map { |metric| Api::Serializer.metric_entry(metric) } }
      end

      # GET /api/v1/corrections/:metric
      def show
        metric = Metrics::Catalog.find(params[:metric])
        return render json: { error: "没有这项指标" }, status: :not_found unless metric

        measurements = current_api_user.measurements
          .where(metric_type: metric.key)
          .order(recorded_on: :desc, recorded_at: :desc)
        render json: {
          metric: Api::Serializer.metric_entry(metric),
          measurements: measurements.map { |measurement| Api::Serializer.measurement(measurement) }
        }
      end
    end
  end
end
