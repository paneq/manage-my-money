ActiveRecord::Schema.define(:version => 0) do

  create_table :users, :force => true do |t|
    t.string :name, :string
  end

  create_table :categories, :force => true do |t|
    t.column :name, :string
    t.references :user
  end

  create_table :transfers, :force => true do |t|
    t.column :description, :string
    t.references :user, :null => false
    t.references :category
  end

  create_table :transfer_items, :force => true do |t|
    t.column :description, :string
    t.references :transfer
    t.references :category
  end

  create_table :tags, :force => true do |t|
    t.column :name, :string
    t.references :transfer_item
    t.references :category
  end

end
