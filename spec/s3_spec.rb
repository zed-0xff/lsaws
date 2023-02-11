# frozen_string_literal: true

RSpec.describe "s3" do
  before :all do
    require "aws-sdk-s3"
  end

  it "defaults to buckets" do
    expect(Aws::S3::Client).to receive(:new).and_wrap_original do |m, *_args|
      m.call(stub_responses: true).tap do |client|
        expect(client).to receive(:list_buckets).and_call_original
      end
    end
    Lsaws::CLI.new(%w[s3]).run!
  end

  ["buckets", :default].each do |x|
    describe x do
      before do
        expect(Aws::S3::Client).to receive(:new).and_wrap_original do |m, *_args|
          @data = AwsCliSample.get_rubydoc_example("s3", "list_buckets")
          m.call(stub_responses: { list_buckets: @data })
        end
        @args = x == :default ? "s3" : "s3 buckets"
      end

      it "outputs a table" do
        sample = <<~EOF
        ┌────────────────┬─────────────────────────┐
        │ name           │ creation_date           │
        ├────────────────┼─────────────────────────┤
        │ examplebucket  │ 2012-02-15 21:03:02 UTC │
        │ examplebucket2 │ 2011-07-24 19:33:50 UTC │
        │ examplebucket3 │ 2010-12-17 00:56:49 UTC │
        └────────────────┴─────────────────────────┘
        EOF
        table = run! "#{@args} --max-width 120"
        expect(table).to eq(sample)
      end

      it "outputs JSON" do
        src = JSON.parse(AwsCliSample.get_rubydoc_example("s3", "list_buckets")[:buckets].to_json)
        dst = JSON.parse(run!("#{@args} -o json"))
        expect(dst).to eq(src)
      end
    end
  end
end
