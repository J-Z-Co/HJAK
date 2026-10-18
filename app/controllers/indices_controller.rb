class IndicesController < ApplicationController
  before_action :authenticate_user!

  def index
    @board = ::Indices::Board.assemble(current_user)
    @brief = ::Indices::Brief.for(@board)
  end

  def overview
    @board = ::Indices::Board.assemble(current_user)
  end

  def show
    @board = ::Indices::Board.assemble(current_user)
    @reading = @board.readings.find { |reading| reading.key == params[:key] }
    unless @reading
      redirect_to indices_path, alert: "没有这项指数"
      return
    end
    unless @reading.clickable
      redirect_to indices_path, alert: @reading.note.presence || "这项不单独画图"
      return
    end

    @series = ::Indices::Series.call(user: current_user, key: @reading.key, range: params[:range])
    @explanation = ::Indices::Assessment.explanation(@reading.key, years: @board.years)
  end
end
