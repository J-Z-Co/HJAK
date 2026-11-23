module Api
  module V1
    class CorrectionEntriesController < BaseController
      before_action :load_metric
      before_action :load_measurement

      # PATCH/PUT /api/v1/corrections/:metric/entries/:id  { value:, value_secondary? }
      def update
        error = ::Measurements::BatchCreate.check(@metric, params[:value], params[:value_secondary])
        return render json: { errors: { value: [ error ] } }, status: :unprocessable_entity if error

        decimals = @metric.blood_pressure? ? 0 : 2
        @measurement.update!(
          value: ::Measurements::BatchCreate.parse(params[:value], decimals: decimals),
          value_secondary: @metric.blood_pressure? ? ::Measurements::BatchCreate.parse(params[:value_secondary], decimals: 0) : nil
        )
        render json: { measurement: Api::Serializer.measurement(@measurement) }
      end

      # DELETE /api/v1/corrections/:metric/entries/:id
      def destroy
        @measurement.destroy!
        render json: { notice: "已删除这次记录" }
      end

      private

      def load_metric
        @metric = Metrics::Catalog.find(params[:metric])
        return if @metric

        render json: { error: "没有这项指标" }, status: :not_found
      end

      def load_measurement
        return if performed?

        @measurement = current_api_user.measurements.find_by(id: params[:id], metric_type: @metric.key)
        render json: { error: "只能修改自己的记录" }, status: :forbidden unless @measurement
      end
    end
  end
end
