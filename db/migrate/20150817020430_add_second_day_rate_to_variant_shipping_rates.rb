class AddSecondDayRateToVariantShippingRates < ActiveRecord::Migration
  def change
    add_column :spree_variant_shipping_rates, :second_day_rate, :decimal, :null => true, :default => nil
  end
end