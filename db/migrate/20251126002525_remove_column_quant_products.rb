class RemoveColumnQuantProducts < ActiveRecord::Migration[7.1]
  def change
    remove_column :products, :quantity, :integer, default: 1
  end
end
