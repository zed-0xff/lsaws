# frozen_string_literal: true

RSpec.describe "ec2" do
  before :all do
    require "aws-sdk-ec2"
  end

  it "defaults to instances" do
    expect(Aws::EC2::Client).to receive(:new).and_wrap_original do |m, *_args|
      m.call(stub_responses: true).tap do |client|
        expect(client).to receive(:describe_instances).and_call_original
      end
    end
    Lsaws::CLI.new(%w[ec2]).run!
  end

  ["instances", :default].each do |x|
    describe x do
      before do
        expect(Aws::EC2::Client).to receive(:new).and_wrap_original do |m, *_args|
          @data = AwsCliSample.get_awscli_example("ec2", "describe_instances")
          m.call(stub_responses: { describe_instances: @data })
        end
        @args = x == :default ? "ec2" : "ec2 instances"
      end

      it "outputs a table" do
        sample = <<~EOF
          ┌─────────────────────┬─────────────┬───────────────────────┬────────────────────┬─────────────────────────┐
          │ instance_id         │ name        │ vpc_id                │ private_ip_address │ launch_time             │
          ├─────────────────────┼─────────────┼───────────────────────┼────────────────────┼─────────────────────────┤
          │ i-1234567890abcdef0 │ my-instance │ vpc-1234567890abcdef0 │ 10-0-0-157         │ 2022-11-15 10:48:59 UTC │
          └─────────────────────┴─────────────┴───────────────────────┴────────────────────┴─────────────────────────┘
        EOF
        table = run! "#{@args} --max-width 120"
        expect(table).to eq(sample)
      end

      it "outputs JSON" do
        src = AwsCliSample.get_awscli_example("ec2", "describe_instances", transform_values: false, symbolize: false)
                          .dig("reservations", 0, "instances")
        dst = JSON.parse(to_iso8601(run!("#{@args} -o json")))
        expect(dst).to eq(src)
      end
    end
  end

  describe "images" do
    before do
      expect(Aws::EC2::Client).to receive(:new).and_wrap_original do |m, *_args|
        @data = AwsCliSample.get_awscli_example("ec2", "describe_images")
        m.call(stub_responses: { describe_images: @data })
      end
    end

    it "outputs a table" do
      sample = <<~EOF
        ┌───────────────────────┬──────────────────────────────────────────────┬──────────────────────────┐
        │ image_id              │ name                                         │ creation_date            │
        ├───────────────────────┼──────────────────────────────────────────────┼──────────────────────────┤
        │ ami-1234567890EXAMPLE │ RHEL-8.0.0_HVM-20190618-x86_64-1-Hourly2-GP2 │ 2019-05-10T13:17:12.000Z │
        └───────────────────────┴──────────────────────────────────────────────┴──────────────────────────┘
      EOF
      table = run! %w[ec2 images --max-width 120]
      expect(table).to eq(sample)
    end

    it "outputs JSON" do
      src = AwsCliSample.get_awscli_example("ec2", "describe_images", transform_values: false,
                                                                      symbolize: false)["images"]
      dst = JSON.parse(to_iso8601(run!(%w[ec2 images -o json])))
      expect(dst).to eq(src)
    end
  end
end
