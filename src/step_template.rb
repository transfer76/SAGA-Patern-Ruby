class StepTemplate
  def initialize
    @connection = Faraday.new(
      url: 'CHANGEME',
      headers: {'Content-Type' => 'application/json'}
    )
    
    @resource = 'CHANGEME'
  end

  # Update this method according to your needs
  # output should be stored in @entities variable as array
  def preload_entities
    @entities = JSON.parse(@connection.get(@resource).body)
  end

  def get_initialized_substeps
    @entities.map do |entity|
      {
        object_id: entity.id,
        object: BaseStep.new(entity, @connection, @resource),
        status: SUBSTEP_STATUSES[:pending],
        results: {}
      }
    end
  end
end
