class CategorySweeper < ActionController::Caching::Sweeper
  observe Category

  def after_save(category)
    clear_quick_access_cache(category)
    clear_cache(category)
  end

  def after_destroy(category)
    clear_quick_access_cache(category)
  end

  def clear_quick_access_cache(category)
    expire_fragment("#{category.user.id}-quick-categories")
  end

  def clear_cache(category)
    category.self_and_descendants.each do |c|
      Rails.cache.delete(c.level_cache_key)
      Rails.cache.delete(c.name_with_path_cache_key)
    end

  end

end