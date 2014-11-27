class CreateVariantShippingRates < ActiveRecord::Migration
  def change
    create_table :spree_variant_shipping_rates do |t|
      t.references :variant, index: true
      t.references :zone, index: true
      t.decimal :standard_rate

      t.timestamps
    end

    add_index :spree_variant_shipping_rates, [:variant_id, :zone_id], :unique => true
  end
end
