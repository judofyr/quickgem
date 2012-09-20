require 'bundler'
require 'bundler/lazy_specification'
require 'bundler/definition'

module Bundler
  class LazySpecification
    def __materialize__
      @specification =  Gem::Dependency.new(name, version).to_spec
    end
  end

  class Definition
    def specs
      @specs ||= begin
        specs = resolve.materialize(requested_dependencies)

        unless specs["bundler"].any?
          bundler = Gem::Dependency.new('bundler', VERSION).to_spec
          specs["bundler"] = bundler if bundler
        end

        specs
      end
    end
  end
end

