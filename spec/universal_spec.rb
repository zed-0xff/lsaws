# frozen_string_literal: true

sdks =
  case ENV["SDK"]
  when nil
    Lsaws::SDKParser.get_sdks
  when /[*?]/
    Lsaws::SDKParser.get_sdks.find_all { |sdk| File.fnmatch(ENV["SDK"], sdk) }
  else
    ENV["SDK"].split
  end

sdks.each do |sdk|
  sdkp = Lsaws::SDKParser.new(sdk)
  etypes = sdkp.entity_types
  if etypes.empty?
    puts "[?] #{sdk}: no entities"
    next
  end
  RSpec.describe sdk do
    etypes.each do |etype|
      describe etype do
        before do
          method_name = sdkp.etype2method(etype)
          expect(sdkp.client_class).to receive(:new).and_wrap_original do |m, *_args|
            if ENV["AWS_RESPONSE_GENERATOR"] == "live"
              m.call
            else
              @data = AwsCliSample.get(sdk, method_name)
              # endpoint was required by `iotdataplane` SDK for some reason
              m.call(stub_responses: { method_name.to_sym => @data }, endpoint: "https://localhost:2222")
            end
          end
          @args = "#{sdk} #{etype}"
        end

        it "outputs a table" do
          cmd = "#{@args} --max-width 120"
          cmd = "#{cmd} --debug" if ENV["DEBUG"]
          table = run! cmd
          warn(table) if ENV["DEBUG"] || ENV["SHOW"]
          expect(table.split("\n").size).to be >= 5
        end
      end
    end
  end
end
