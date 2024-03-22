class TogodbGraphsController < ApplicationController
  def show
    @togodb_graph = TogodbGraph.find_by(togodb_column_id: params[id])
  end

  def update
    @togodb_graph = TogodbGraph.find(params[:id])
    @togodb_graph.update!(graph_params)
  end

  private

  def graph_params
    params.require(:togodb_graph).permit(:togodb_column_id, :embed_tag)
  end
end
