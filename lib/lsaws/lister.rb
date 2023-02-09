# frozen_string_literal: true

require "aws-sdk-core"
require "json"
require "tabulo"
require "yaml"

module Lsaws
  class Lister
    CONFIG = YAML.load_file(File.join(Lsaws.root, "lsaws.yml"))

    def initialize(options)
      @options = options
    end

    def _prepare_entities(sdk, type)
      edef = CONFIG.dig(sdk, type)
      return _prepare_entities(sdk, edef) if edef.is_a?(String) # redirect like 'default' -> 'instances'

      edef ||= {}
      require(edef["require"] || "aws-sdk-#{sdk}")

      params = edef["default_params"] || {}
      if @options[:filters].any?
        params[:filters] = @options[:filters].map { |k, v| { name: k, values: [v] } }
      elsif edef["default_filter"]
        params[:filters] = [edef["default_filter"]]
      end
      params[:max_results] = @options[:max_results] if @options[:max_results]

      sdkp = SDKParser.new(sdk)
      client_class = edef["client_class"] || sdkp.client_class_name
      client = Kernel.const_get(client_class).new
      method_name = edef["method"] || (client.respond_to?("describe_#{type}") ? "describe_#{type}" : "list_#{type}")
      unless client.respond_to?(method_name)
        if type == "default"
          warn "[!] no default entity type set for #{sdk.inspect} SDK"
        else
          warn "[!] #{sdk.inspect} SDK does not have #{type.inspect} entity type"
        end
        puts "Known entity types are:"
        list_entity_types(sdk)
        exit 1
      end
      results = client.send(method_name, params)

      pp results if @options[:debug]

      if !edef["result_keys"] && results.any?
        r = results.first
        r = r.last if r.is_a?(Array)
        edef["result_keys"] = if r.respond_to?(type)
                                [type]
                              else
                                [(r.members - [:next_token]).first]
                              end
      end
      edef["result_keys"].each do |key|
        results = if results.is_a?(Array)
                    results.map(&key.to_sym).flatten
                  else
                    results.send(key)
                  end
      end
      edef["cols"] = @options[:show_cols] if @options[:show_cols].any?

      col_defs = {}
      Array(edef["cols"]).each do |r|
        case r
        when String, Symbol
          col_defs[r] = proc { |entity| entity.send(r) }
        when Hash
          col_defs.merge!(r)
        else
          raise Error, "unexpected #{r.inspect}"
        end
      end
      col_defs["tags"] = _convert_tags_proc if @options[:show_tags] || col_defs["tags"]

      results ||= []
      if results.any? && !results.first.respond_to?(:name)
        results.first.class.class_eval do
          def name
            tags.find { |tag| tag.key == "Name" }&.value
          end
        end
      end

      # ec2 instance_event_notification_attributes
      # 'Array(results)' doesn't work here
      results = [results] unless results.is_a?(Array)

      if block_given?
        results.map do |entity|
          yield entity, col_defs
        end
      else
        [results, col_defs]
      end
    end

    def entities2records(sdk, type)
      rows, cols = _prepare_entities(sdk, type)
      if rows.is_a?(Array) && rows[0].is_a?(String)
        # sqs
        cols = { value: proc { |entity| entity } }
      elsif rows.respond_to?(:members)
        rows = [rows]
      end
      [rows, cols]
    end

    def entities2hashes(sdk, type)
      rows =
        if @options[:show_cols].any?
          # show cols specified on cmdline
          _prepare_entities(sdk, type) do |entity, _col_defs|
            case entity
            when String
              { value: entity } # might conflict with show_cols, let's always display for now
            else
              @options[:show_cols].map { |c| [c, entity.send(c)] }.to_h
            end
          end
        else
          # either predefined cols from YAML or automatic ones
          _prepare_entities(sdk, type) do |entity, _col_defs|
            case entity
            when String
              { value: entity }
            else
              # ec2 instance_event_notification_attributes
              entity.to_h
            end
          end
        end
      if rows&.first&.key?("tags")
        rows.each do |row|
          row["tags"] = row["tags"].map { |tag| [tag.key, tag.value] }.to_h
        end
      end
      rows
    end

    # only for table/text view
    def _convert_tags_proc
      proc { |entity| entity.tags.map { |tag| "#{tag.key}=#{tag.value}" }.join(", ") }
    end

    def list_sdks
      _list_array SDKParser.get_sdks
    end

    def _list_array(a)
      case @options[:format]
      when :json
        puts a.to_json
      when :yaml
        puts a.to_yaml
      else
        puts a.join("\n")
      end
    end

    def list_entity_types(sdk)
      _list_array SDKParser.new(sdk).entity_types
    end

    def _tabulo_guess_max_cols(rows, _cols)
      max_cols = rows[0].members.size
      return max_cols if max_cols < 4 || !@options[:max_width]

      4.upto(max_cols) do |ncols|
        tbl = Tabulo::Table.new(rows[0, 100], *rows[0].members[0, ncols])
        tbl.autosize_columns
        tbl_width = tbl.column_registry.values.map { |c| c.padded_width + 1 }.inject(:+) + 1
        return ncols - 1 if tbl_width >= @options[:max_width]
      end
      max_cols
    end

    def process_command(sdk, type = "default")
      if sdk == :list
        return list_sdks
      elsif type == :list
        return list_entity_types(sdk)
      elsif type == :all
        get_entity_types(sdk).each do |etype|
          puts "#{etype}:"
          process_command(sdk, etype)
        end
        return
      end

      case @options[:format]
      when :text, :table
        @options[:max_width] ||= ($stdout.tty? ? TTY::Screen.width : nil)

        rows, cols = entities2records(sdk, type)
        return unless rows.any?

        style = @options[:format] == :text ? :blank : :modern

        tbl = Tabulo::Table.new(rows, border: style, align_header: :left, header_frequency: @options[:header])
        if cols.any?
          cols.each { |name, func| tbl.add_column(name, &func) }
        else
          max_cols = _tabulo_guess_max_cols(rows, cols)
          rows[0].members[0, max_cols].each { |col| tbl.add_column(col) }
        end
        puts tbl.pack(max_table_width: @options[:max_width])
      when :json
        rows = entities2hashes(sdk, type)
        puts rows.to_json
      when :'json-stream', :js
        rows = entities2hashes(sdk, type)
        rows.each do |row|
          puts row.to_json
        end
      when :yaml
        rows = entities2hashes(sdk, type)
        rows.each { |row| Utils._deep_transform_keys_in_object!(row, &:to_s) }
        puts rows.to_yaml
      else
        warn "[!] unknown format: #{@options[:format]}"
        exit 1
      end
    rescue Aws::Errors::ServiceError => e
      warn "[!] #{e}"
    end
  end
end
