# frozen_string_literal: true

RSpec.describe Lsaws do
  it "has a version number" do
    expect(Lsaws::VERSION).not_to be nil
  end

  it "does something useful" do
    p AwsCliSample.get("ec2", "describe-instances")
  end
end
