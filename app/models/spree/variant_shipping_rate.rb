module Spree
	class VariantShippingRate < ActiveRecord::Base

		belongs_to :variant
		belongs_to :zone

	end
end
