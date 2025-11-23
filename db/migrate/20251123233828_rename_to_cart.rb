class RenameToCart < ActiveRecord::Migration[7.1]
  def change
    rename_column :carts, :total_price, :cart_value
  end
end
