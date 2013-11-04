# -*- coding: UTF-8 -*-
# Config file

require 'railroadmap/rails/root'

# railroadmap/config.rb
class ConfigFile
  def new_config(railroadmap_dir, config_file)
    # create dir
    Dir.mkdir(railroadmap_dir) if File.exists?(railroadmap_dir) == false

    # Check application routes
    ard = Rails::Root.new
    root_list = ard.get_root_dirs_from_gems
    $log.debug "Show root list"
    pp root_list if $log.debug?

    open(config_file, "w") do |f|
      f.write "# RailroadMap config file\n"

      # $rails_version
      f.write "\n"
      f.write "# Rails version\n"
      f.write "$rails_version='#{$rails_version}'\n"
      f.write "\n"

      # $approot_list
      unless root_list.nil?
        # List
        # v 0.1.0
        # f.write "\n"
        # f.write "# Application root paths v0.1.0\n"
        # f.write "$approot_list = [\n"
        # root_list.each do |k, v|
        #   f.write "  '#{v[1]}',\n"
        # end
        # f.write "]\n"

        # v0.2.0
        f.write "\n"
        f.write "# Application root paths v0.2.0\n"
        f.write "$approot_hash = {\n"
        i = 0
        root_list.each do |k, v|
          f.write "  '#{k}' => {\n"
          f.write "     dir: '#{v[1]}',\n"
          f.write "     # option: 'except_views',\n"
          f.write "  },\n"
        end
        f.write "}\n"
      end

     # $authentication
      f.write "\n"
      f.write "# Authentication\n"
      if $authentication.nil?
        f.write "$authentication = nil\n"
      else
        f.write "$authentication = '#{$authentication}'\n"
      end

      # $authorization
      f.write "\n"
      f.write "# Authorization\n"
      if $authorization.nil?
        f.write "$authorization = nil\n"
      else
        f.write "$authorization = '#{$authorization}'\n"
      end

      # $test
      f.write "\n"
      f.write "# Authorization\n"
      if $test.nil?
        f.write "$test = nil\n"
      else
        f.write "$test = '#{$test}'\n"
      end

      f.write "\n"
      f.write "# Display transition from layout (BSD is getting busy)\n"
      f.write "$bsd_display_layout = false\n"
      f.write "\n"
      f.write "# EOF\n"
    end
  end
end
