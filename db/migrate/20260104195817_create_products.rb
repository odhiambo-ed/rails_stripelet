class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :product_id
      t.string :name
      t.text :description
      t.boolean :active
      t.jsonb :metadata

      t.timestamps
    end
  end
end
