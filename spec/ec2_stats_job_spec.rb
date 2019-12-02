RSpec.describe Ec2StatsJob do
  it "has a version number" do
    expect(Ec2StatsJob::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(defined?(Ec2StatsJob::Job)).to eq('constant')
    expect(defined?(Ec2StatsJob::Client)).to eq('constant')
  end
end
