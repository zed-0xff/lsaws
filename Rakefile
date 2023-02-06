def gem_dirs_list
  h = Hash.new{ |k,v| k[v] = {} }
  Gem.path.each do |p|
    next unless Dir.exist?(p)
    Dir[File.join(p, "gems/aws-sdk-*")].each do |gem_dir|
      a = File.basename(gem_dir).split('-')
      version = Gem::Version.new(a.pop)
      name = a.join('-')
      h[name][version] = gem_dir
    end
  end
  h.values.map{ |vers| vers[vers.keys.max] }
end

def process_gem_dir dir
  puts "[.] #{dir}"

  a = File.basename(dir).sub("aws-sdk-", "").split("-")
  return if a.size == 1 # "aws-sdk-3.1.0"
  raise a.inspect unless a.size == 2
  sdk = a[0]
  return if sdk == 'core'

  fnames = Dir[File.join(dir, "**", "client.rb")]
  return unless fnames.any?

  rdoc = RDoc::RDoc.new
  rdoc.options = RDoc::Options.load_options
  rdoc.options.verbosity = 0
  store = rdoc.store = RDoc::Store.new

  cdef = { 'class' => nil, 'entities' => {} }
  rdoc.parse_files fnames
  store.classes_hash.each do |class_name, class_info|
    class_info.method_list.each do |m|
      if m.name =~ /^(describe|list)_.+s$/ && m.name !~ /(status|access)$/
        desc = m.comment.text.split(/\. |\n/,2).first[0,100]
        puts "    #{m.name} - #{desc}"
        e = m.name.sub(/^(describe|list)_/,'')
        cdef['entities'][e] = {
          'method' => m.name
        }
        if cdef['class']
          raise if cdef['class'] != class_name
        else
          cdef['class'] = class_name
          puts "  #{class_name}"
        end
      end
    end
  end

  fname = File.join("data", "#{sdk}.yml")
  File.write(fname, cdef.to_yaml)
end

namespace :parse do
  desc "parse AWS SDKs"
  task :aws_sdks do
    require 'rdoc'
    require 'yaml'
    gem_dirs_list.each do |dir|
      process_gem_dir dir
    end
  end
end
