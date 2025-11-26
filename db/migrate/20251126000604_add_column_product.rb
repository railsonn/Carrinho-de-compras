class AddColumnProduct < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :quantity, :integer, default: 1
  end
end
