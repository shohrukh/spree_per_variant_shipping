module Spree
  module Calculator
    module Shipping
      module PerVariant
        class Base < Spree::ShippingCalculator

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
            unless rates.nil?
              filtered_rates = rates.select { |rate| self.class.synnex_shipping_codes.include? rate['code'] }
              if filtered_rates.size
                filtered_rates = filtered_rates.map { |rate| rate['Freight'].delete(',').to_f }
                filtered_rates.min
              end
            end
          end

        end
      end
    end
  end
end
