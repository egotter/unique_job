RSpec.describe UniqueJob::Util do
  class TestUniqueJobUtil
    include UniqueJob::Util
  end

  let(:instance) { TestUniqueJobUtil.new }
  let(:history) { double('history') }

  before do
    instance.instance_variable_set(:@history, history)
  end

  class TestUtilWorker
    def unique_key(*args, **kwargs)
      args.inspect + kwargs.inspect
    end

    def unique_in
      10
    end
  end

  describe "#perform" do
    let(:worker) { TestUtilWorker.new }
    let(:job) { {'class' => TestUtilWorker.name, 'args' => ['arg1', 'arg2']} }
    let(:block) { Proc.new { 'result' } }
    subject { instance.perform(worker, job, &block) }

    context 'worker has #unique_key' do
      let(:unique_key) { 'key' }

      before do
        allow(worker).to receive(:unique_key).with(*job['args']).and_return(unique_key)
      end

      context 'key is nil' do
        let(:unique_key) { nil }
        it { is_expected.to eq(block.call) }
      end

      context 'key is empty' do
        let(:unique_key) { '' }
        it { is_expected.to eq(block.call) }
      end

      context 'history found' do
        let(:unique_key) { 'key' }
        before { allow(history).to receive(:exists?).with(job['class'], unique_key).and_return(true) }
        it do
          expect(instance).to receive(:perform_callback).with(worker, :after_skip, job['args'])
          subject
        end
      end

      context 'history is not found' do
        let(:unique_key) { 'key' }
        before { allow(history).to receive(:exists?).with(job['class'], unique_key).and_return(false) }
        it do
          expect(history).to receive(:add).with(job['class'], unique_key, 10)
          subject
        end
      end
    end

    context 'worker does not have #unique_key' do
      before { allow(worker).to receive(:respond_to?).with(:unique_key).and_return(false) }
      it { is_expected.to eq(block.call) }
    end
  end
end
