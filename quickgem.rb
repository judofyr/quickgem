require 'rubygems'
require 'rubygems/specification'
require 'pathname'
require 'digest/md5'

module QuickGem
  CACHE_BASE = Pathname.new(File.expand_path('../cache', __FILE__))

  class Path
    attr_reader :path

    def initialize(path)
      @path = Pathname.new(path)
    end

    def md5
      Digest::MD5.hexdigest(@path.to_path)
    end

    def cache_dir
      CACHE_BASE + md5
    end

    def stale?
      spec_dir.exist? and
        !cache_dir.exist? || cache_dir.mtime < spec_dir.mtime
    end

    def cache_lib
      cache_dir + "lib"
    end

    def cache_gem
      cache_dir + "gem"
    end

    def spec_dir
      @path + "specifications"
    end

    def specs
      @specs ||= Dir[spec_dir + "*.gemspec"].map do |file|
        Gem::Specification.load(file)
      end
    end

    def spec_data(spec)
      {
        :name => spec.name,
        :version => spec.version,
        :spec_file => spec.spec_file,
      }
    end

    def sort(specs)
      specs.sort! { |a, b|
        names = a.name <=> b.name
        if names.nonzero?
          names
        else
          b.version <=> a.version
        end
      }
    end

    def build
      title = cache_lib.exist? ? "Rebuilding" : "Building"
      warn "[QuickGem] #{title} cache for #{@path}"

      build_lib
      build_gem
    end

    def build_lib
      cache_lib.rmtree if cache_lib.exist?
      lib_tree.each do |file, specs|
        path = cache_lib + file
        path.parent.mkpath unless path.parent.exist?
        File.open(path, "w") do |f|
          f.binmode
          sort(specs)
          f << Marshal.dump(specs.map(&method(:spec_data)))
        end
      end
    end

    def lib_tree
      tree = Hash.new { |h, k| h[k] = [] }
      specs.each do |spec|
        Dir[spec.lib_dirs_glob].each do |dir|
          Dir[dir + "/**/*{#{Gem.suffixes.join(',')}}"].each do |file|
            next unless File.file?(file)
            rel = file[(dir.size+1)..-1]
            tree[rel] << spec
          end
        end
      end
      tree
    end

    def build_gem
      cache_gem.rmtree if cache_gem.exist?
      cache_gem.mkpath

      gem_tree.each do |name, specs|
        path = cache_gem + name
        File.open(path, "w") do |f|
          f.binmode
          sort(specs)
          f << Marshal.dump(specs.map(&method(:spec_data)))
        end
      end
    end

    def gem_tree
      tree = Hash.new { |h, k| h[k] = [] }
      specs.each do |spec|
        tree[spec.name] << spec
      end
      tree
    end

    def find_by_lib(file, &blk)
      full = Gem.suffixes.map { |s| cache_lib + "#{file}#{s}" }
      full.each do |path|
        if File.file?(path)
          Marshal.load(File.binread(path)).each(&blk)
        end
      end

      nil
    end

    def find_by_gem(name, requirement)
      path = cache_gem + name
      if File.file?(path)
        datas = Marshal.load(File.binread(path))
        datas.each do |data|
          if requirement.satisfied_by? data[:version]
            return Gem::Specification.load(data[:spec_file])
          end
        end
      end

      nil
    end
  end

  PATHS = Gem.paths.path.map { |path| Path.new(path) }

  def self.build
    PATHS.each do |path|
      path.build
    end
  end
end

class << Gem
  alias try_activate_without_quickgem try_activate
  alias bin_path_without_quickgem bin_path

  def try_activate(file)
    QuickGem::PATHS.each do |path|
      path.find_by_lib(file) do |data|
        spec = Gem::Specification.load(data[:spec_file])
        spec.activate
        return true
      end
    end

    false
  end

  def bin_path(name, exec_name = nil, *requirements)
    if spec = Gem.loaded_specs[name]
      return spec.bin_file exec_name
    end

    bin_path_without_quickgem(name, exec_name, *requirements)
  end
end

class Gem::Dependency
  alias to_specs_without_quickgem to_specs
  alias to_spec_without_quickgem to_spec

  def to_spec
    QuickGem::PATHS.each do |path|
      if spec = path.find_by_gem(name, requirement)
        return spec
      end
    end

    nil
  end

  def to_specs
    res = []

    QuickGem::PATHS.each do |path|
      if spec = path.find_by_gem(name, requirement)
        res << spec
      end
    end

    res
  end
end

module Kernel
  alias require_without_quickgem require

  def require(file)
    if Gem.unresolved_deps.empty?
      require_without_quickgem(file)
    else
      QuickGem::PATHS.each do |path|
        path.find_by_lib(file) do |data|

          if Gem.unresolved_deps.has_key?(data[:name])
            reqs = Gem.unresolved_deps[data[:name]]
            next unless reqs.all? { |req| req.satisfied_by?(data[:version]) }
          end

          spec = Gem::Specification.load(data[:spec_file])
          spec.activate
          return gem_original_require(file)
        end
      end

      gem_original_require(file)
    end 
  end
end

$QUICKGEM_ALL = false

class << Gem::Specification
  alias _all_without_quickgem _all

  def _all
    if !$QUICKGEM_ALL
      puts "Fallback at:"
      puts caller
      $QUICKGEM_ALL = true
    end

    _all_without_quickgem
  end
end if ENV['QUICKGEM_DEBUG']

if $0 == __FILE__
  QuickGem.build
  exit
end

# Make sure everything is up to date.
QuickGem::PATHS.each do |path|
  path.build if path.stale?
end

