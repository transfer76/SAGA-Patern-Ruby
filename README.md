# [Prototype] How to use?

### Create step logic using interface from step_template file
1. Fill all `CHANGEME` fields with values
2. Change connection adapter if you need
3. Change `preload_entities` logic if you need (output should be stored in @entities variable as array)

### Example of migration service setup:
```ruby
saga = MigrationService.new(forward: true/false)
saga.register_step(:RoastBeans)
saga.register_step(:MeltBeans)
saga.register_step(:BrewCoffee)
saga.run_transaction
```
