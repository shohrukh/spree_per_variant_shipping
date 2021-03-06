module SpreePerVariantShipping
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_per_variant_shipping'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc

    initializer 'spree.register.per_variant_shipping_calculators', :after => 'spree.register.calculators' do |app|
      app.config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::PerVariant::Ground
    end
  end
end
