# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc "build readme"
task :readme do
  require "erb"
  tpl = File.read("README.md.tpl").gsub(/^%\s+(.+)/) do |x|
    x.sub!(/^%/, "")
    "<%= run(\"#{x}\") %>"
  end
  def run(cmd)
    cmd.strip!
    puts "[.] #{cmd} ..."
    r = "    # #{cmd}\n\n"
    cmd.sub!(/^lsaws/, "./exe/lsaws")
    lines = `#{cmd}`.sub(/\A\n+/m, "").sub(/\s+\Z/, "").split("\n")
    lines = lines[0, 25] + ["..."] if lines.size > 50
    r << lines.map { |x| "    #{x}" }.join("\n")
    r << "\n"
  end
  result = ERB.new(tpl).result
  File.open("README.md", "w") { |f| f << result }
end
