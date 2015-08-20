namespace :spree_per_variant_shipping do
  namespace :update do

    desc 'Synchronize shipping prices with Synnex (Florida => California, Alaska, Hawaii)'
    task :synnex => :environment do

      begin
        # Make sure Synnex related setting are set
        raise 'Synnex related settings are not configured' unless Spree::Dropship::Config.synnex_configured?
        synnex_supplier = Spree::Dropship::Config.synnex_supplier

        # Set Florida warehouse as shipping origin
        ship_from_warehouse_id = synnex_supplier.get_preference(:warehouse_16_stock_location)
        raise 'Ship From warehouse ID is not configured' if ship_from_warehouse_id.nil?
        ship_from_warehouse = Spree::StockLocation.find(ship_from_warehouse_id)

        puts 'Updating variants information'
        Spree::SupplierProduct.where(:supplier => synnex_supplier).each do |sp|
          puts
          puts "Updating shipping price for #{sp.variant.id} - #{sp.variant.sku}"

          # Create a dummy order for shipping rate calculation
          order = Spree::Order.new()

          package = Spree::Stock::Package.new(ship_from_warehouse)
          package.add(Spree::InventoryUnit.new(:variant => sp.variant, :order => order))

          # Shipping destination addresses (California (used for Contiguous US), Alaska, Hawaii)
          shipping_addresses = [
              Spree::Address.new(:firstname => "Sean", :lastname => "Shoyoqubov", :address1 => "508 Elm Street", :city => "San Carlos", :zipcode => '94070', :state_id => 32, :country_id => 49),
              Spree::Address.new(:firstname => "Sean", :lastname => "Shoyoqubov", :address1 => "800 Cushman Street", :city => "Fairbanks", :zipcode => '99701', :state_id => 50, :country_id => 49),
              Spree::Address.new(:firstname => "Sean", :lastname => "Shoyoqubov", :address1 => "530 South King Street", :city => "Honolulu", :zipcode => '96813', :state_id => 17, :country_id => 49)
          ]

          shipping_calculators = {
              'ground' => Spree::Calculator::Shipping::Synnex::Ground.new(),
              'second_day' => Spree::Calculator::Shipping::Synnex::SecondDay.new()
          }

          per_variant_ground_calculator = Spree::Calculator::Shipping::PerVariant::Ground.find(4)

          shipping_addresses.each do |shipping_address|
            package.order.shipping_address = shipping_address

            ship_to_zone = per_variant_ground_calculator.calculable.zones.match(shipping_address)

            shipping_calculators.each { |calculator_name, calculator_instance|
              shipping_rate = nil
              retries = 0

              while shipping_rate.nil? && retries < 2 do
                shipping_rate = calculator_instance.compute_package(package)

                if shipping_rate.nil?
                  if retries >= 1
                    puts "-- ERROR: Fetching of #{calculator_name.camelize} rate for variant #{sp.variant.id} (SKU: #{sp.variant.sku}) to #{shipping_address.state.name} FAILED!"
                  else
                    Rails.cache.delete(calculator_instance.cache_key(package))
                    puts "-- NOTICE: Retrying fetching of #{calculator_name.camelize} rate for variant #{sp.variant.id} (SKU: #{sp.variant.sku}) to #{shipping_address.state.name}"
                  end
                  retries += 1
                else
                  # Add 20% margin on top of shipping rate to cover our expenses and create buffer
                  shipping_rate = shipping_rate * 1.20

                  # Find or create per variant shipping record
                  variant_shipping_rate = Spree::VariantShippingRate.where(:variant => sp.variant, :zone => ship_to_zone).first_or_create!
                  variant_shipping_rate["#{calculator_name}_rate"] = shipping_rate
                  variant_shipping_rate.save!
                  puts "-- #{calculator_name.camelize} rate for variant #{sp.variant.id} (SKU: #{sp.variant.sku}) to #{shipping_address.state.name}: #{Spree::Money.new(shipping_rate)}"
                end
              end
            }

            # Sleep to avoid server overwhelming
            sleep(5)
          end
        end
      rescue => e
        puts e
      end

    end

  end
end