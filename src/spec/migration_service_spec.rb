require "ostruct"
require 'rspec'
require_relative '../autoload'
require_relative 'shared_examples/success'
require_relative 'shared_examples/failure'

class TestStep1
  def initialize
    @connection = Faraday.new
    
    @resource = '/test1/'
  end

  def prepare_data(ctx: {})
    @test_data = JSON.parse(@connection.get(@resource))
  end

  def initialize_substeps(step)
    @test_data.map do |item|
      body = {}

      step.initialize_substep(item, @connection, @resource, body)
    end
  end
end

class TestStep2
  def initialize
    @connection = Faraday.new
    
    @resource = '/test2/'
  end

  def prepare_data(ctx: {})
    @test_data = JSON.parse(@connection.get(@resource))
  end

  def initialize_substeps(step)
    @test_data.map do |item|
      body = {}

      step.initialize_substep(item, @connection, @resource, body)
    end
  end
end

RSpec.describe MigrationService do
  subject(:service_call) do
    migration_service = described_class.new(forward: forward)
    migration_service.register_step(:TestStep1)
    migration_service.register_step(:TestStep2)
    migration_service.run_transaction
    migration_service
  end

  let(:entity_1) { { 'id' => 1 } }
  let(:entity_2) { { 'id' => 2 } }
  let(:entity_3) { { 'id' => 3 } }
  let(:entity_4) { { 'id' => 4 } }
  let(:entities) { [entity_1, entity_2, entity_3, entity_4] }

  let(:faraday_stub_1) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_stub_2) { Faraday::Adapter::Test::Stubs.new }
  let(:stubed_array_1) do
    [
      entity_1,
      entity_2
    ]
  end
  let(:stubed_array_2) do
    [
      entity_3,
      entity_4
    ]
  end
  let(:valid_response_status_1) { 201 }
  let(:valid_response_status_2) { 204 }
  let(:valid_response_1) do
    OpenStruct.new(
      body: entity_1.to_json,
      status: valid_response_status_1
    )
  end
  let(:valid_response_2) do
    OpenStruct.new(
      body: entity_2.to_json,
      status: valid_response_status_2
    )
  end
  let(:valid_response_3) do
    OpenStruct.new(
      body: entity_3.to_json,
      status: valid_response_status_1
    )
  end
  let(:valid_response_4) do
    OpenStruct.new(
      body: entity_4.to_json,
      status: valid_response_status_2
    )
  end
  let(:invalid_response_1) do
    OpenStruct.new(
      body: {},
      status: 400
    )
  end
  let(:step_stub_1) { TestStep1.new }
  let(:step_stub_2) { TestStep2.new }

  before do
    allow(Faraday).to receive(:new).and_return(faraday_stub_1, faraday_stub_2)
    allow(faraday_stub_1).to receive(:get).and_return(stubed_array_1.to_json)
    allow(faraday_stub_2).to receive(:get).and_return(stubed_array_2.to_json)

    allow(faraday_stub_1).to receive(:put).and_return(valid_response_1, valid_response_2)
    allow(faraday_stub_2).to receive(:put).and_return(valid_response_3, valid_response_4)
  end

  describe 'SUCCESS' do
    let(:expected_complete_steps_array) { ['TestStep1.1', 'TestStep1.2', 'TestStep2.1', 'TestStep2.2'] }
    let(:expected_last_completed_step) { 'TestStep2.2' }

    context 'when forward' do
      let(:forward) { true }

      it 'correctly sets migration_method' do
        expect(service_call.instance_variable_get(:@migrate_method)).to eq :migrate
      end
    
      it 'correctly sets revert_method' do
        expect(service_call.instance_variable_get(:@revert_method)).to eq :revert
      end

      it_behaves_like 'success'
    end

    context 'when backward' do
      let(:forward) { false }

      it 'correctly sets migration_method' do
        expect(service_call.instance_variable_get(:@migrate_method)).to eq :revert
      end
    
      it 'correctly sets revert_method' do
        expect(service_call.instance_variable_get(:@revert_method)).to eq :migrate
      end

      it_behaves_like 'success'
    end
  end

  describe 'FAILURE' do
    context 'when forward' do
      let(:forward) { true }

      context 'when system error' do
        let(:expected_complete_steps_array) { ["TestStep1.1", "TestStep1.2"] }
        let(:expected_last_completed_step) { 'TestStep1.2' }

        before do
          allow_any_instance_of(TestStep2).to receive(:prepare_data).and_raise(StandardError)
        end

        it 'correctly sets migration_method' do
          expect(service_call.instance_variable_get(:@migrate_method)).to eq :migrate
        end
      
        it 'correctly sets revert_method' do
          expect(service_call.instance_variable_get(:@revert_method)).to eq :revert
        end

        it 'cancels current step' do
          expect(service_call.ctx.steps[:TestStep2].status).to eq Context::STEP_STATUSES[:canceled]
        end

        it 'reverts previous 201 status substeps' do
          expect(service_call.ctx.steps[:TestStep1].substeps[0].status).to eq Context::SUBSTEP_STATUSES[:reverted]
          expect(service_call.ctx.steps[:TestStep1].substeps[1].status).to eq Context::SUBSTEP_STATUSES[:succeeded]
        end

        it_behaves_like 'failure'
      end

      context 'when invalid response' do
        let(:expected_complete_steps_array) { [] }
        let(:expected_last_completed_step) { nil }
        let(:expected_failed_step) { 'TestStep1.1' }

        before do
          allow_any_instance_of(BaseStep).to receive(:migrate).and_return(invalid_response_1)
        end

        it 'correctly sets migration_method' do
          expect(service_call.instance_variable_get(:@migrate_method)).to eq :migrate
        end

        it 'correctly sets revert_method' do
          expect(service_call.instance_variable_get(:@revert_method)).to eq :revert
        end

        it 'fails first step' do
          expect(service_call.ctx.steps[:TestStep1].status).to eq Context::STEP_STATUSES[:failed]
        end

        it 'cancels second step' do
          expect(service_call.ctx.steps[:TestStep2].status).to eq Context::STEP_STATUSES[:canceled]
        end

        it 'currently sets statuses for next substeps' do
          expect(service_call.ctx.steps[:TestStep1].substeps[1].status).to eq Context::SUBSTEP_STATUSES[:canceled]
        end

        it_behaves_like 'failure'
      end

      context 'when revert failed' do
        let(:expected_complete_steps_array) {["TestStep1.1", "TestStep1.2"] }
        let(:expected_last_completed_step) { 'TestStep1.2' }
        let(:expected_failed_step) { 'TestStep1.1' }

        before do
          allow_any_instance_of(TestStep2).to receive(:initialize_substeps).and_raise(StandardError)
          allow_any_instance_of(BaseStep).to receive(:revert).and_return(invalid_response_1)
        end

        it 'correctly sets migration_method' do
          expect(service_call.instance_variable_get(:@migrate_method)).to eq :migrate
        end
      
        it 'correctly sets revert_method' do
          expect(service_call.instance_variable_get(:@revert_method)).to eq :revert
        end

        it 'cancels current step' do
          expect(service_call.ctx.steps[:TestStep2].status).to eq Context::STEP_STATUSES[:canceled]
        end

        it 'returns revert failed substep' do
          expect(service_call.ctx.steps[:TestStep1].substeps[0].status).to eq Context::SUBSTEP_STATUSES[:revert_failed]
        end

        it 'return succeeded step' do
          expect(service_call.ctx.steps[:TestStep1].substeps[1].status).to eq Context::SUBSTEP_STATUSES[:succeeded]
        end

        it_behaves_like 'failure'
      end
    end

    context 'when backward' do
      let(:forward) { false }

      context 'when system error' do
        let(:expected_complete_steps_array) { ["TestStep1.1", "TestStep1.2"] }
        let(:expected_last_completed_step) { 'TestStep1.2' }

        before do
          allow_any_instance_of(TestStep2).to receive(:prepare_data).and_raise(StandardError)
        end

        it 'correctly sets migration_method' do
          expect(service_call.instance_variable_get(:@migrate_method)).to eq :revert
        end
      
        it 'correctly sets revert_method' do
          expect(service_call.instance_variable_get(:@revert_method)).to eq :migrate
        end

        it 'cancels current step' do
          expect(service_call.ctx.steps[:TestStep2].status).to eq Context::STEP_STATUSES[:canceled]
        end

        it 'reverts previous 201 status substeps' do
          expect(service_call.ctx.steps[:TestStep1].substeps[0].status).to eq Context::SUBSTEP_STATUSES[:reverted]
          expect(service_call.ctx.steps[:TestStep1].substeps[1].status).to eq Context::SUBSTEP_STATUSES[:succeeded]
        end

        it_behaves_like 'failure'
      end

      context 'when invalid response' do
        let(:expected_complete_steps_array) { [] }
        let(:expected_last_completed_step) { nil }
        let(:expected_failed_step) { 'TestStep1.1' }

        before do
          allow_any_instance_of(BaseStep).to receive(:revert).and_return(invalid_response_1)
        end

        it 'correctly sets migration_method' do
          expect(service_call.instance_variable_get(:@migrate_method)).to eq :revert
        end

        it 'correctly sets revert_method' do
          expect(service_call.instance_variable_get(:@revert_method)).to eq :migrate
        end

        it 'fails first step' do
          expect(service_call.ctx.steps[:TestStep1].status).to eq Context::STEP_STATUSES[:failed]
        end

        it 'cancels second step' do
          expect(service_call.ctx.steps[:TestStep2].status).to eq Context::STEP_STATUSES[:canceled]
        end

        it 'currently sets statuses for next substeps' do
          expect(service_call.ctx.steps[:TestStep1].substeps[1].status).to eq Context::SUBSTEP_STATUSES[:canceled]
        end

        it_behaves_like 'failure'
      end

      context 'when revert failed' do
        let(:expected_complete_steps_array) {["TestStep1.1", "TestStep1.2"] }
        let(:expected_last_completed_step) { 'TestStep1.2' }
        let(:expected_failed_step) { 'TestStep1.1' }

        before do
          allow_any_instance_of(TestStep2).to receive(:initialize_substeps).and_raise(StandardError)
          allow_any_instance_of(BaseStep).to receive(:migrate).and_return(invalid_response_1)
        end

        it 'correctly sets migration_method' do
          expect(service_call.instance_variable_get(:@migrate_method)).to eq :revert
        end
      
        it 'correctly sets revert_method' do
          expect(service_call.instance_variable_get(:@revert_method)).to eq :migrate
        end

        it 'cancels current step' do
          expect(service_call.ctx.steps[:TestStep2].status).to eq Context::STEP_STATUSES[:canceled]
        end

        it 'returns revert failed substep' do
          expect(service_call.ctx.steps[:TestStep1].substeps[0].status).to eq Context::SUBSTEP_STATUSES[:revert_failed]
        end

        it 'return succeeded step' do
          expect(service_call.ctx.steps[:TestStep1].substeps[1].status).to eq Context::SUBSTEP_STATUSES[:succeeded]
        end

        it_behaves_like 'failure'
      end
    end
  end
end
