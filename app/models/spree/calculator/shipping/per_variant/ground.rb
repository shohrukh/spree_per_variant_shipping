module Spree
  module Calculator::Shipping
    module PerVariant
      class Ground < Spree::Calculator::Shipping::PerVariant::Base

        def self.description
          I18n.t("per_variant.shipping.ground")
        end

        # Returns the hash key with the method name
        def code
          :ground
        end

      end
    end
  end
end