class RemoveTableCartItem < ActiveRecord::Migration[7.1]
  def change
    drop_table :cart_items
  end
end
