require_relative '../autoload'

require_relative 'steps/roast_beans'
require_relative 'steps/melt_beans'
require_relative 'steps/brew_coffee'

# saga = MigrationService.new(forward: false)
saga = MigrationService.new
saga.register_step(:RoastBeans)
saga.register_step(:MeltBeans)
saga.register_step(:BrewCoffee)
saga.run_transaction
binding.pry
