class GoalsController < ApplicationController

  layout 'main'
  before_filter :login_required


  def index
    @actual_goals = Goal.find_actual(self.current_user)
    @finished_goals = Goal.find_past(self.current_user)
  end


  def show
    @goal = self.current_user.goals.find(params[:id])
  end


  def new
    @goal = Goal.new
    prepare_values_for_goal_type_and_currency
  end


  def edit
    @goal = self.current_user.goals.find(params[:id])
    prepare_values_for_goal_type_and_currency
  end


  def create
    @goal = Goal.new(params[:goal])
    @goal.user = self.current_user
    @goal.set_period(get_period 'goal_day')
    if @goal.save
      flash[:notice] = 'Cel został utworzony.'
      redirect_to(:action => :index)
    else
      prepare_values_for_goal_type_and_currency
      render :action => "new"
    end
  end


  def update
    @goal = self.current_user.goals.find(params[:id])
    @goal.set_period(get_period 'goal_day')
    if @goal.update_attributes(params[:goal])
      flash[:notice] = 'Cel został zapisany.'
      redirect_to(:action => :index)
    else
      prepare_values_for_goal_type_and_currency
      render :action => "edit"
    end
  end


  def destroy
    @goal = self.current_user.goals.find(params[:id])
    @goal.destroy
    redirect_to(goals_url)
  end


  def finish
    @goal = self.current_user.goals.find(params[:id])
    if @goal.finish
      flash[:notice] = 'Plan został zakończony.'
    else
      flash[:notice] = 'Plan nie został zakończony. Skontaktuj się z pomocą techniczną.'
    end

    redirect_to(:action => :index)
  end


  def history_index
    @goal = self.current_user.goals.find(params[:id])
    @goals = @goal.all_goals_in_cycle
  end


  private

  def prepare_values_for_goal_type_and_currency
    @values_for_goal_type_and_currency = self.current_user.visible_currencies.map { |cur| [cur.long_symbol, cur.long_symbol]}
    @values_for_goal_type_and_currency << ['Procent wartości z nadkategorii','percent']
  end

end
