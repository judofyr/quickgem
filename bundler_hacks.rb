require 'bundler'
require 'bundler/lazy_specification'
require 'bundler/definition'

module Bundler
  class LazySpecification
    old_materialize = instance_method(:__materialize__)
    define_method(:__materialize__) do
      if source.is_a?(Bundler::Source::Rubygems)
        @specification = Gem::Dependency.new(name, version).to_spec
      else
        old_materialize.bind(self).call
      end
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

