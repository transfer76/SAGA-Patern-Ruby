shared_examples_for 'success' do
  it 'completes operation' do
    expect(service_call.ctx.status).to eq Context::STATUSES[:completed]
  end

  it 'succeeds all steps' do
    service_call.ctx.steps.each_value do |step|
      expect(step.status).to eq Context::STEP_STATUSES[:succeeded]
    end
  end

  it 'succeeds all substeps' do
    service_call.ctx.steps.each_value do |step|
      step.substeps.each do |substep|
        expect(substep.status).to eq Context::SUBSTEP_STATUSES[:succeeded]
      end
    end
  end

  it 'returns valid response statuses' do
    service_call.ctx.steps.each_value do |step|
      step.substeps.each do |substep|
        expect(substep.status).to eq Context::SUBSTEP_STATUSES[:succeeded]
      end
    end
  end

  it 'returns valid response bodies' do
    counter = 0

    service_call.ctx.steps.each_value do |step|
      step.substeps.each do |substep|
        expect(substep.results[:response_body]).to eq entities[counter]

        counter += 1
      end
    end
  end

  it 'correctly stores completed_steps variables' do
    expect(service_call.ctx.completed_steps).to eq expected_complete_steps_array
  end

  it 'correctly stores last_completed_step variable' do
    expect(service_call.ctx.last_completed_step).to eq expected_last_completed_step
  end

  it 'clears current_step_class' do
    expect(service_call.instance_variable_get(:@current_step_class)).to be_nil
  end

  it 'clears current_step_ctx' do
    expect(service_call.instance_variable_get(:@current_step_ctx)).to be_nil
  end

  it 'clears current_step_ctx' do
    expect(service_call.instance_variable_get(:@current_substep)).to be_nil
  end

  it 'clears current_substep for each step' do
    service_call.ctx.steps.each_value do |step|
      expect(step.current_substep).to be_nil
    end
  end
end
