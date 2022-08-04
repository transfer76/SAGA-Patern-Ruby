module Context
  class Substep
    attr_reader :id, :status, :command, :results

    def initialize(entity:, connection:, resource:, step_name:, index:, body:)
      @id       = "#{step_name}.#{index}"
      @status   = Context::SUBSTEP_STATUSES[:pending]
      @command  = ::BaseStep.new(entity: entity, connection: connection, resource: resource, body: body)
      @results  = {}

      generate_status_methods
    end

    def build_result(response, error: false)
      @results[:response_status] = response.status

      if error
        @results[:response_body] = response.body
      else
        @results[:response_body] = JSON.parse(response.body)
      end
    end

    private

    def generate_status_methods
      # Substep statuses:
      # pending_status!
      # succeeded_status!
      # reverted_status!
      # failed_status!
      # revert_failed_status!
      # canceled_status!
      Context::SUBSTEP_STATUSES.values.each do |status_value|
        self.class.define_method("#{status_value.downcase}_status!") do
          @status = status_value
        end
      end
    end
  end
end
