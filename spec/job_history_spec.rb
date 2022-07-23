RSpec.describe UniqueJob::JobHistory do
  let(:redis) { Redis.new }
  let(:instance) { described_class.new('TestMiddleware', redis) }

  before do
    Redis.new.flushall
  end

  describe '#exists?' do
    let(:v1) { 'Worker' }
    let(:v2) { 'key' }
    subject { instance.exists?(v1, v2) }

    it { is_expected.to be_falsey }

    context 'history includes value' do
      before { instance.add(v1, v2, 10) }
      it { is_expected.to be_truthy }
    end

    context 'error is raised' do
      before { allow(redis).to receive(:exists?).with(instance_of(String)).and_raise('error') }
      it { expect { subject }.not_to raise_error }
    end
  end

  describe '#add' do
    let(:v1) { 'Worker' }
    let(:v2) { 'key' }
    let(:ttl) { 10 }
    subject { instance.add(v1, v2, ttl) }

    before { allow(instance).to receive(:key).with(v1, v2).and_return('w:k') }

    it do
      subject
      expect(redis.get('w:k')).to eq('true')
      expect(redis.ttl('w:k')).to eq(10)
    end

    context 'error is raised' do
      before { allow(redis).to receive(:setex).with(instance_of(String), ttl, true).and_raise('error') }
      it { expect { subject }.not_to raise_error }
    end
  end

  describe '#key' do
    let(:v1) { 'Worker' }
    let(:v2) { 'key' }
    subject { instance.send(:key, v1, v2) }
    it { is_expected.to eq('UniqueJob::JobHistory:TestMiddleware:Worker:key') }
  end
end
