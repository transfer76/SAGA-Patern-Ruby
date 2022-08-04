class RoastBeans
  def initialize
    @connection = Faraday.new(
      url: 'http://127.0.0.1:5001',
      headers: {'Content-Type' => 'application/json'}
    )
    
    @resource = '/beans/'
  end

  def prepare_data(ctx: {})
    response_data = JSON.parse(@connection.get(@resource).body)['data']

    @data = response_data.map do |response_item|
      {
        'id' => response_item[0]
      }
    end
  end

  def initialize_substeps(step)
    @data.map do |item|
      body = {}

      step.initialize_substep(item, @connection, @resource, body)
    end
  end
end
