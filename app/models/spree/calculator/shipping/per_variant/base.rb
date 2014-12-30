module Spree
  module Calculator::Shipping
    module PerVariant
      class Base < Spree::ShippingCalculator

        # Returns the hash key with the method name. Override in specific implementation.
        def code
          raise(NotImplementedError, 'please use concrete PerVariant calculator')
        end

        # Returns the hash of shipping methods available with their costs for package
        def fetch_rates(package)
          zone = self.calculable.zones.match(package.order.ship_address)
          return nil if zone.nil?

          rates = { :ground => nil, :standard => nil }

          package.contents.each do |line_item|
            ship_rate = Spree::VariantShippingRate.where(:zone => zone, :variant => line_item.variant).take
            unless ship_rate.nil?
              rates[:standard] = rates[:standard].to_f + (ship_rate.standard_rate * line_item.quantity) if ship_rate.standard_rate
              rates[:ground] = rates[:ground].to_f + (ship_rate.ground_rate * line_item.quantity) if ship_rate.ground_rate
            end
          end

          rates
        end

        # Return a unique cache key for a package for use by Rails cache
        def cache_key(package)
          stock_location = package.stock_location.nil? ? "" : "#{package.stock_location.id}"
          ship_address = package.order.ship_address
          contents_hash = Digest::MD5.hexdigest(package.contents.map {|content_item| content_item.variant.id.to_s + "_" + content_item.quantity.to_s }.join("|"))
          @cache_key = "Spree::Calculator::Shipping::PerVariant-#{stock_location}-#{package.order.number}-#{ship_address.country.iso}-#{ship_address.state_text}-#{ship_address.city}-#{ship_address.zipcode}-#{contents_hash}-#{I18n.locale}".gsub(" ","")
        end

        def cached_fetch_rates(package)
          Rails.cache.fetch(cache_key(package), expires_in: 1.hour) do
            fetch_rates(package)
          end
        end

        def available?(package)
          !compute(package).nil?
        end

        def compute_package(package)
          rates = cached_fetch_rates(package)
          return nil if rates.nil?

          rates[code]
        end

      end
    end
  end
end
