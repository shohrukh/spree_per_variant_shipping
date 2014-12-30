module Spree
  module Admin
    class VariantShippingRatesController < ResourceController

      belongs_to 'spree/product'
      before_filter :load_variants
      # before_filter :load_zones

      private

      def collection
        @collection = parent.variant_shipping_rates
      end

      def load_variants
        @variants = parent.variants.empty? ? [parent.master] : parent.variants
      end

      # def load_zones
      #   @zones = Spree::Zone
      # end

    end
  end
end
