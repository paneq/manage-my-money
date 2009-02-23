class CategorySweeper < ActionController::Caching::Sweeper
  observe Category

  def after_save(category)
    clear_quick_access_cache(category)
  end

  def after_destroy(category)
    clear_quick_access_cache(category)
  end

  def clear_quick_access_cache(category)
    expire_fragment("#{category.user.id}-quick-categories")
  end
end