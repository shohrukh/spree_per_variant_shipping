Spree::Product.class_eval do

  has_many :variant_shipping_rates, :through => :variants_including_master

end
