RSpec.describe UniqueJob::Util do
  class TestUniqueJobUtil
    include UniqueJob::Util
  end

  let(:instance) { TestUniqueJobUtil.new }

  class TestUtilWorker
    def unique_key(*args, **kwargs)
      args.inspect + kwargs.inspect
    end

    def unique_in
      10
    end
  end

  describe "#perform_if_unique" do
    let(:worker) { TestUtilWorker.new }
    let(:args) { ['arg1', 'arg2'] }
    let(:job) { {'class' => TestUtilWorker.to_s, 'args' => args} }
    let(:block) { Proc.new { 'result' } }
    let(:unique_key) { 'key' }
    subject { instance.perform_if_unique(worker, job, &block) }

    context 'The worker has #unique_key' do
      before do
        allow(worker).to receive(:unique_key).with(*args).and_return(unique_key)
      end

      context 'Succeed the uniqueness check' do
        before { allow(instance).to receive(:check_uniqueness).with(worker, unique_key).and_return(true) }
        it { is_expected.to eq(block.call) }
      end

      context 'Fail the uniqueness check' do
        before { allow(instance).to receive(:check_uniqueness).with(any_args).and_return(false) }
        it do
          expect(instance).to receive(:perform_callback).with(worker, :after_skip, args)
          is_expected.to be_nil
        end
      end
    end

    context "The worker doesn't have #unique_key" do
      before { allow(worker).to receive(:respond_to?).with(:unique_key).and_return(false) }
      it { is_expected.to eq(block.call) }
    end
  end

  describe "#check_uniqueness" do
    let(:worker) { double('worker') }
    let(:unique_key) { 'key' }
    let(:history) { double('job_history') }
    let(:existence) { nil }
    subject { instance.check_uniqueness(worker, unique_key) }

    before do
      allow(instance).to receive(:job_history).with(worker).and_return(history)
      allow(history).to receive(:exists?).with(unique_key).and_return(existence)
    end

    context 'The key is nil or an empty string' do
      [nil, ''].each do |key|
        let(:unique_key) { key }
        it do
          expect(instance).not_to receive(:job_history)
          is_expected.to be_falsey
        end
      end
    end

    context 'The key exists in the history' do
      let(:existence) { true }
      it { is_expected.to be_falsey }
    end

    context "The key doesn't exist in the history" do
      let(:existence) { false }
      it do
        expect(history).to receive(:add).with(unique_key)
        is_expected.to be_truthy
      end
    end
  end

  describe '#job_history' do
    let(:worker) { double('worker') }
    subject { instance.job_history(worker) }

    context 'The worker has #unique_in' do
      before { allow(worker).to receive(:unique_in).and_return(60) }
      it do
        expect(UniqueJob::JobHistory).to receive(:new).with(worker.class, instance.class, 60)
        subject
      end
    end

    context "The worker doesn't have #unique_in" do
      before { allow(worker).to receive(:respond_to?).with(:unique_in).and_return(false) }
      it do
        expect(UniqueJob::JobHistory).to receive(:new).with(worker.class, instance.class, 3600)
        subject
      end
    end
  end
end
