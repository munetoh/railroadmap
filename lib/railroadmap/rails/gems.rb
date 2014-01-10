# -*- coding: UTF-8 -*-
# gems.rb

module Rails
  # Application root
  class Gems
    def initialize
      # TBD
      @gems = {}  # TODO: name: {version:, path: warnings:{brakeman:, codesake-dawn:}}
    end
    attr_accessor :gems

    def init

      ver0 = Gem::Version.create(Gem::RubyGemsVersion)
      ver1 = Gem::Version.create('1.8')  # TODO: temp
      if ver0 < ver1
        $log.error "gem version #{ver0} is old < #{ver1}"
        searcher = Gem::GemPathSearcher.new
        specs = searcher.init_gemspecs
      else
        # gem --version 1.3.7.1
        # `init': undefined method `find_all' for Gem::Specification:Class
        # gem --version 1.8.25
        specs = Gem::Specification.find_all # {|spec| spec.contains_requirable_file? path}
        specs = specs.sort_by { |spec| spec.version }
      end

      specs.each do |spec|
        $log.debug "spec name : #{spec.name}"

        @gems[spec.name] = { version: spec.version, path: spec.full_gem_path }

        # TODO: pick the first (newone), must check the Gemfile?
        if spec.name == 'rails'
          if $rails_version.nil?
            $log.debug "rails version is #{spec.version}"
            $rails_version = spec.version.to_s
          end
        end
      end
    end

    def print_gems
      @gems.each do |k, g|
        puts "    #{k.rjust(20)}  #{g[:version].to_s.rjust(10)} #{g[:command_library]} #{g[:warnings]}"
      end
    end

  end  # class
end  # module
