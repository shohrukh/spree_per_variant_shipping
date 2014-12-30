class AddGroundRateToVariantShippingRates < ActiveRecord::Migration
  def change
    add_column :spree_variant_shipping_rates, :ground_rate, :decimal, :null => true, :default => nil
    change_column :spree_variant_shipping_rates, :standard_rate, :decimal, :null => true, :default => nil
  end
end
