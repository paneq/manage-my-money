class GraphController < ApplicationController
  def test
    @graph = open_flash_chart_object(600,300,"/graph/graph_code")
  end
  def graph_code
    title = Title.new("MY TITLE")
    bar = BarGlass.new
    bar.set_values([1,2,3,4,5,6,7,8,9])
    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.add_element(bar)
    render :text => chart.to_s
  end

end
