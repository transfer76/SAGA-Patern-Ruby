class BaseStep
  def initialize(entity:, connection:, resource:, body:)
    @entity       = entity
    @connection   = connection
    @resource     = resource
    @body         = body
  end

  def migrate
    @connection.put("#{@resource}#{@entity['id']}/migrate", **@body)
  end

  def revert
    @connection.put("#{@resource}#{@entity['id']}/revert")
  end

  private

  def inspect
    {
      entity: @entity,
      resource: @resource,
      body: @body
    }
  end
end
