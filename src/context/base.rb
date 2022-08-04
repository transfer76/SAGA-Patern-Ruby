module Context
  class Base
    attr_reader :steps, :forward, :status, :completed_steps, :last_completed_step, :failed_step, :system_errors

    def initialize(forward:)
      @status               = Context::STATUSES[:pending]

      @steps                = {}
      @completed_steps      = []
      @system_errors        = []

      @last_completed_step  = nil
      @failed_step          = nil
      @forward              = forward

      generate_status_methods
    end

    def success?
      status == :completed && failed_step.empty? && system_errors.empty?
    end

    def failing?
      status == Context::STATUSES[:failing]
    end

    def initialzie_step(step_class)
      @steps[step_class] = Context::Step.new(step_class)
    end

    def write_failed_step(step_id)
      @failed_step = step_id
    end

    def add_system_error(error)
      @system_errors << error
    end

    def complete_substep!(step_id)
      @completed_steps << step_id
      @last_completed_step = step_id
    end

    private

    def generate_status_methods
      # High level status methods:
      # pending_status!
      # processing_status!
      # completed_status!
      # failing_status!
      Context::STATUSES.values.each do |status_value|
        self.class.define_method("#{status_value.downcase}_status!") do
          @status = status_value
        end
      end
    end
  end
end
