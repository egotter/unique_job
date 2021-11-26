RSpec.describe UniqueJob::Logging do
  class TestUniqueJobLogging
    include UniqueJob::Logging
  end

  let(:instance) { TestUniqueJobLogging.new }

  describe '#logger' do
    subject { instance.logger.info 'a' }
    it { is_expected.to be_truthy }
  end
end
