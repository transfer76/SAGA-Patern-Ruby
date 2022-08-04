module Context
  class Step
    attr_reader :status, :substeps, :current_substep

    def initialize(name)
      @name             = name
      @status           = Context::STATUSES[:pending]
      @substeps         = []
      @current_substep  = nil

      generate_status_methods
    end

    def initialize_substep(entity, connection, resource, body)
      @substeps << Context::Substep.new(
        entity: entity,
        connection: connection,
        resource: resource,
        step_name: @name,
        index: substeps.count + 1,
        body: body
      )
    end

    def write_current_substep(substep)
      @current_substep = substep
    end

    private

    def generate_status_methods
      # Status methods:
      # pending_status!
      # processing_status!
      # succeeded_status!
      # failed_status!
      # canceled_status!
      Context::STEP_STATUSES.values.each do |status_value|
        self.class.define_method("#{status_value.downcase}_status!") do
          @status = status_value
        end
      end
    end
  end
end
