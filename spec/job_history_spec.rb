RSpec.describe UniqueJob::JobHistory do
  class TestWorker; end

  class TestMiddleware; end

  let(:instance) { described_class.new(TestWorker, TestMiddleware, 60) }
  let(:redis) { Redis.new }

  before do
    Redis.new.flushall
    described_class.redis_options = {host: 'localhost'}
  end

  describe '#ttl' do
    subject { instance.ttl(val) }

    context 'val is passed' do
      let(:val) { 'value' }
      before { instance.add(val) }
      it { is_expected.to eq(60) }
    end

    context 'val is nil' do
      let(:val) { nil }
      it { is_expected.to eq(60) }
    end
  end

  describe '#exists?' do
    let(:val) { 'value' }
    subject { instance.exists?(val) }

    it { is_expected.to be_falsey }

    context 'history includes value' do
      before { instance.add(val) }
      it { is_expected.to be_truthy }
    end

    context 'redis raises an exception' do
      before { allow(redis).to receive(:exists).with(any_args).and_raise('error') }
      it { expect { subject }.not_to raise_error }
    end
  end

  describe '#add' do
    let(:val) { 'value' }
    subject { instance.add(val) }

    before { allow(instance).to receive(:key).with(val).and_return('key') }

    it do
      subject
      expect(redis.get('key')).to eq('true')
      expect(redis.ttl('key')).to eq(60)
    end

    context 'redis raises an exception' do
      before { allow(redis).to receive(:setex).with(any_args).and_raise('error') }
      it { expect { subject }.not_to raise_error }
    end
  end

  describe '#key' do
    let(:val) { 'value' }
    subject { instance.send(:key, val) }
    it { is_expected.to eq("UniqueJob::JobHistory:TestMiddleware:TestWorker:value") }
  end
end

RSpec.describe UniqueJob::JobHistory::RescueAllRedisErrors do
  let(:instance) do
    Class.new {
      def ttl(*args)
        raise 'error'
      end

      def exists?(*args)
        raise 'error'
      end

      def add(*args)
        raise 'error'
      end

      prepend UniqueJob::JobHistory::RescueAllRedisErrors
    }.new
  end

  describe '#ttl' do
    subject { instance.ttl }
    it { expect { subject }.not_to raise_error }
  end

  describe '#exists?' do
    subject { instance.exists? }
    it { expect { subject }.not_to raise_error }
  end

  describe '#add' do
    subject { instance.add }
    it { expect { subject }.not_to raise_error }
  end
end
