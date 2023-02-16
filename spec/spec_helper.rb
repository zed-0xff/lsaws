# frozen_string_literal: true

require "lsaws"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

include Lsaws::Utils

# run with capturing stdout and stderr
# return [success?, stdout, stderr]
# can catch exit()
def run(args)
  args = args.split if args.is_a?(String)
  out, err = StringIO.new, StringIO.new
  saved_out, $stdout = $stdout, out
  saved_err, $stderr = $stderr, err
  Lsaws::CLI.new(args).run!
  [true, out.string, err.string]
rescue SystemExit => e
  [e.success?, out.string, err.string]
ensure
  $stdout = saved_out
  $stderr = saved_err
end

# run with capturing stdout only
# return stdout as string
def run!(args)
  args = args.split if args.is_a?(String)
  out = StringIO.new
  saved_out, $stdout = $stdout, out
  Lsaws::CLI.new(args).run!
  out.string
ensure
  $stdout = saved_out
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
