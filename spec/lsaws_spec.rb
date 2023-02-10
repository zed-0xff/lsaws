# frozen_string_literal: true

RSpec.describe Lsaws do
  it "has a version number" do
    expect(Lsaws::VERSION).not_to be nil
  end

  describe "s3" do
    it "does something useful" do
      require "aws-sdk-s3"
      expect(Aws::S3::Client).to receive(:new).and_wrap_original do |m, *_args|
        m.call(stub_responses: { list_buckets: { buckets: [{ name: "foo" }] } })
      end
      Lsaws::CLI.new(%w[s3]).run!
    end
  end
end
