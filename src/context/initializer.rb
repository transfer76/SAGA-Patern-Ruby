require_relative 'substep'
require_relative 'step'
require_relative 'base'

module Context
  STATUSES = {
    pending: 'PENDING',
    processing: 'PROCESSING',
    completed: 'COMPLETED',
    failing: 'FAILING'
  }

  STEP_STATUSES = {
    pending: 'PENDING',
    processing: 'PROCESSING',
    failed: 'FAILED',
    succeeded: 'SUCCEEDED',
    canceled: 'CANCELED'
  }
  
  SUBSTEP_STATUSES = {
    pending: 'PENDING',
    succeeded: 'SUCCEEDED',
    reverted: 'REVERTED',
    failed: 'FAILED',
    revert_failed: 'REVERT_FAILED',
    canceled: 'CANCELED'
  }

  class Initializer
    class << self
      def call(forward:)
        Base.new(forward: forward)
      end
    end
  end
end
