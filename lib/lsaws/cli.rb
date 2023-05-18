# frozen_string_literal: true

require "optparse"

module Lsaws
  class CLI
    SUPPORTED_FORMATS = %w[table yaml json json-stream js text].sort
    DEFAULT_FORMAT    = :table

    def initialize(argv)
      @options = {
        format: DEFAULT_FORMAT,
        header: true,
        filters: {},
        show_cols: [],
        max_results: nil
      }
      @commands = option_parser.parse!(argv)
      if @options[:all]
        raise Error, "Unsupported arguments combination" if @commands.size != 1

        @commands << :all
      end
      @commands << :list if @options[:list]
    end

    def option_parser
      @option_parser ||=
        OptionParser.new do |opt|
          opt.banner = "Usage: lsaws [options] <sdk> [entity_type]"

          opt.on("-p", "--profile PROFILE", "AWS profile") do |o|
            @options[:profile] = o
            ENV['AWS_PROFILE'] = o
          end

          opt.on("-o", "--output FMT", SUPPORTED_FORMATS, "Format: #{SUPPORTED_FORMATS.join("/")}") do |f|
            @options[:format] = f.to_sym
          end
          opt.on("--no-header", "Suppress header") { @options[:header] = false }
          opt.on("-x", 'Shortcut for "-o text --no-header"') do
            @options[:format] = :text
            @options[:header] = false
          end
          opt.on("--tags", "Show tags") { @options[:show_tags] = true }
          opt.on("-f", "--filter K=V", "Add filter") { |o| @options[:filters].merge!(Hash[*o.split("=", 2)]) }
          opt.on("-C", "--columns C", "Show only specified column(s)") do |o|
            if o[","]
              @options[:show_cols].append(*o.split(","))
            else
              @options[:show_cols] << o
            end
          end
          opt.on("--max-results N", Integer, "Fetch only specified number of results") do |o|
            @options[:max_results] = o
          end
          opt.on("--max-width X", Integer, "max text width for table/text mode, default: auto") do |o|
            @options[:max_width] = o
          end

          opt.separator ""
          opt.on("-v", "--verbose", "Verbose output") { @options[:verbose] = true }
          opt.on("--debug") { @options[:debug] = true }

          opt.separator ""
          opt.on("-L", "--list", "List SDKs or entity types") { @options[:list] = true }
          opt.on("-A", "--all", "List all entity types within SDK") { @options[:all] = true }
        end
    end

    def run!
      case @commands.size
      when 1, 2
        Lister.new(@options).process_command(*@commands)
      else
        puts option_parser.help
        nil
      end
    end
  end
end
