# -*- coding: UTF-8 -*-
# Get root paths
#
#  TODO: rvm? .rvmrc
#

module Rails
  # Application root
  class Root
    def initialize
      # TBD
    end

    # ./app exist => add to the path
    def get_root_dirs_from_gems
      # Get Application root dir and Modules
      hlist = {}
      alist = []

      # All gems
      # NOTE: Gem::GemPathSearcher#initialize is deprecated with no replacement. It will be removed on or after 2011-10-01.
      # searcher = Gem::GemPathSearcher.new
      # list = searcher.init_gemspecs
      # GemPathSearcher => Specification
      path = ""
      specs = Gem::Specification.find_all # {|spec| spec.contains_requirable_file? path}
      specs = specs.sort_by { |spec| spec.version }

      specs.each do |spec|
        $log.debug "spec name : #{spec.name}"

        # TODO: pick the first (newone), must check the Gemfile?
        if spec.name == 'rails'
          if $rails_version.nil?
            $log.debug "rails version is #{spec.version}"
            $rails_version = spec.version.to_s
          end
        end

        # KNOWN security functions
        # authentication
        $authentication = 'devise'    if spec.name == 'devise'
        $authentication = 'authlogic' if spec.name == 'authlogic'  # TODO

        # authorization
        $authorization = 'cancan'   if spec.name == 'cancan'
        $authorization = 'the_role' if spec.name == 'the_role' # TODO

        # test
        # TODO: rspec?
        $test = 'cucumber' if spec.name == 'cucumber'

        c_path =  spec.full_gem_path + '/app/controllers'
        v_path =  spec.full_gem_path + '/app/views'
        if File.exists?(c_path) && File.exists?(v_path)
          if hlist[spec.name].nil?
            # new
            $log.debug "rails app?"
            hlist[spec.name] = [spec.version, spec.full_gem_path]
          else
            # hit, select latest one
            if hlist[spec.name][0] < spec.version
              hlist[spec.name][0] = spec.version
              hlist[spec.name][1] = spec.full_gem_path
            end
          end
        elsif File.exists?(c_path)
          puts "TODO C only #{spec.full_gem_path}"
        elsif File.exists?(v_path)
          puts "TODO V only #{spec.full_gem_path}"
        end
      end
      # Add this app
      hlist['this'] = [nil, Dir.pwd]
      hlist
    end
  end
end
