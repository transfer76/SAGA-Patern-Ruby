class MigrationService
  attr_reader :ctx

  SUCCESS_STATUSES = [201, 204]

  def initialize(forward: true)
    @ctx = Context::Initializer.call(forward: forward)
    
    @current_step_class = nil
    @current_step_ctx   = nil
    @current_substep    = nil
    @migrate_method     = nil
    @revert_method      = nil

    define_flow_methods
  end

  def register_step(step_class)
    ctx.initialzie_step(step_class)
  end

  def run_transaction
    ctx.processing_status!

    process_migrations

    process_failing_flow if ctx.failing?
  rescue StandardError => error
    ctx.add_system_error(error)

    ctx.failing_status!

    process_failing_flow
  ensure
    clear_states
    ctx.completed_status!
  end

  private

  def define_flow_methods
    if @ctx.forward
      @migrate_method = :migrate
      @revert_method  = :revert
    else
      @migrate_method = :revert
      @revert_method  = :migrate
    end
  end

  def process_migrations
    ctx.steps.each do |step_class, step_ctx|
      @current_step_class = step_class
      @current_step       = step_ctx

      @current_step.processing_status!

      make_preparations
      run_substeps
      
      break if ctx.failing?
      
      @current_step.succeeded_status!
    end
  end

  def process_failing_flow
    revert_migrations
    cancel_pending_steps
  end

  def revert_migrations
    ctx.completed_steps.reverse.each do |completed_step_id|
      klass, index = completed_step_id.split('.')

      substep = ctx.steps[klass.intern].substeps[index.to_i - 1]

      next if substep.results[:response_status] == 204

      resolve_revert_step(substep)
    end
  end

  def cancel_pending_steps
    ctx.steps.each do |_, step|
      next unless [Context::STEP_STATUSES[:pending], Context::STEP_STATUSES[:processing], Context::STEP_STATUSES[:failed]].include?(step.status)

      step.canceled_status! if step.status != Context::STEP_STATUSES[:failed]

      step.substeps.each do |substep|
        next if substep.status != Context::SUBSTEP_STATUSES[:pending]

        substep.canceled_status!
      end
    end
  end

  def make_preparations
    step = self.class.const_get(@current_step_class).new

    step.prepare_data(ctx: ctx)
    step.initialize_substeps(@current_step)
  end

  def run_substeps
    @current_step.substeps.each do |substep|
      @current_step.write_current_substep(substep)

      resolve_migration_substep

      break if ctx.failing?
    end
  end

  def resolve_migration_substep
    @current_substep = @current_step.current_substep

    response = @current_substep.command.method(@migrate_method).call

    if SUCCESS_STATUSES.include?(response.status)
      success_step(response)
    else
      fail_step(response)
    end
  end

  def resolve_revert_step(substep)
    response = substep.command.method(@revert_method).call

    if SUCCESS_STATUSES.include?(response.status)
      substep.reverted_status!
      substep.build_result(response)
    else
      substep.revert_failed_status!
      substep.build_result(response, error: true)
    end
  end

  def clear_states
    @current_step_class = nil
    @current_step_ctx   = nil
    @current_substep    = nil

    ctx.steps.each_value { |step| step.write_current_substep(nil) }
  end

  def success_step(response)
    @current_substep.succeeded_status!
    ctx.complete_substep!(@current_substep.id)

    @current_substep.build_result(response)
  end

  def fail_step(response)
    @current_substep.failed_status!
    @current_step.failed_status!
    ctx.failing_status!

    ctx.write_failed_step(@current_substep.id)
    @current_substep.build_result(response, error: true)
  end
end
