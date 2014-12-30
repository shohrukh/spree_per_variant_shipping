namespace :spree_per_variant_shipping do
  namespace :update do

    desc 'Synchronize shipping prices with Synnex (Florida to California)'
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

          # Shipping destination addresses (California (used for Contiguous US), Alaska, Hawaii)
          shipping_addresses = [
              Spree::Address.new(:firstname => "Sean", :lastname => "Shoyoqubov", :address1 => "508 Elm Street", :city => "San Carlos", :zipcode => '94070', :state_id => 32, :country_id => 49),
              Spree::Address.new(:firstname => "Sean", :lastname => "Shoyoqubov", :address1 => "800 Cushman Street", :city => "Fairbanks", :zipcode => '99701', :state_id => 50, :country_id => 49),
              Spree::Address.new(:firstname => "Sean", :lastname => "Shoyoqubov", :address1 => "530 South King Street", :city => "Honolulu", :zipcode => '96813', :state_id => 17, :country_id => 49)
          ]

          shipping_addresses.each do |shipping_address|
            order.ship_address = shipping_address

            package = Spree::Stock::Package.new(ship_from_warehouse, order)
            package.add(nil, 1, :on_hand, sp.variant)

            ground_calculator = Spree::Calculator::Shipping::Synnex::Ground.new()
            ground_rate = nil

            per_variant_ground_calculator = Spree::Calculator::Shipping::PerVariant::Ground.find(4)

            ship_to_zone = per_variant_ground_calculator.calculable.zones.match(shipping_address)

            retries = 0
            while ground_rate.nil? && retries < 5 do
              ground_rate = ground_calculator.compute_package(package)

              if ground_rate.nil?
                if retries >= 4
                  puts "-- ERROR: Fetching of Ground rate for variant #{sp.variant.id} (SKU: #{sp.variant.sku}) to #{shipping_address.state.name} FAILED!"
                else
                  Rails.cache.delete(ground_calculator.cache_key(package))
                  puts "-- NOTICE: Retrying fetching of Ground rate for variant #{sp.variant.id} (SKU: #{sp.variant.sku}) to #{shipping_address.state.name}"
                end
                retries += 1
              else
                # Find or create record for Contiguous US
                variant_shipping_rate = Spree::VariantShippingRate.where(:variant => sp.variant, :zone => ship_to_zone).first_or_create!
                variant_shipping_rate.ground_rate = ground_rate
                variant_shipping_rate.save!
                puts "-- Ground rate for variant #{sp.variant.id} (SKU: #{sp.variant.sku}) to #{shipping_address.state.name}: #{Spree::Money.new(ground_rate)}"
              end

              # Sleep to avoid server overwhelming
              sleep(5)
            end
          end
        end
      rescue => e
        puts e
      end

    end

  end
end