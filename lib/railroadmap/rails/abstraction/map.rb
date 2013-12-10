# -*- coding: UTF-8 -*-

module Abstraction
  # Map
  class Map
    def initialize
      @route_map = nil
      @raw_route_map = nil
    end
    attr_accessor :route_map, :raw_route_map

    # newMap
    def new_map(filename)
      open(filename, "w") do |f|
        f.write "# RailroadMap abstraction map file\n"
        unless @route_map.nil?
          # Raw map
          f.write "\n"
          f.write "# same with rake routes\n"
          f.write "$route_map = {\n"
          @route_map.each do |k, v|
            pathname = "'#{k}'"
            f.write "  #{pathname.rjust(30)} => ['#{v[0]}','#{v[1]}','#{v[2]}','#{v[3]}'],\n"
          end
          f.write "}\n"
          # Railroadmap map
          f.write "\n"
          f.write "# for RailroadMap.  pathname in ruby  =>  state id\n"
          f.write "$path2id = {\n"
          @route_map.each do |k, v|
            pathname      = "'#{k}'"
            at_pathname   = "'@#{k}'"
            pathname_path = "'#{k}_path'"
            pathname_url  = "'#{k}_url'"
            controller = v[0].singularize
            domain   =  controller.gsub('/', ':').  + '#' + v[1]
            idname   = "'C_#{domain}'"
            # TODO: ?
            if v[1] == 'show'
              f.write "  #{at_pathname.rjust(30)}      => #{idname},\n"
            end
            f.write "  #{pathname.rjust(30)}      => #{idname},\n"
            f.write "  #{pathname_path.rjust(35)} => #{idname},\n"
            f.write "  #{pathname_url.rjust(34)}  => #{idname},\n"
          end
          f.write "}\n"
        end
        # TODO: automatically set
        f.write "# Ruby code to abstracted expression (B method)\n"
        f.write "$map_guard = {\n"
        f.write "  '' => '',"
        f.write "}\n"
        f.write "# TODO CFRF automatic?\n"
        f.write "$map_guard_by_block = {\n"
        f.write "  '' => '',"
        f.write "}\n"
        f.write "# Actions at block\n"
        f.write "$map_action = {\n"
        f.write "  '' => '',"
        f.write "}\n"
        f.write "# Variables\n"
        f.write "$map_variable = {\n"
        f.write "  'TODO' => 'TODO',"
        f.write "}\n"
        f.write "# SETS in B model\n"
        f.write "$map_bset_types = {\n"
        f.write "  '' => '',"
        f.write "}\n"
        f.write "# EOF\n"
      end # do
    end

    def get_map
      if $new_routemap
        get_map_new  # v3.1 4.0
      else
        get_map_old  # V3.0
      end
    end

    def get_map_new
      map  = ''
      map += "$route_map = {  # new format 20130725\n"

      @raw_route_map.each do |route|
        defaults = route[:defaults]
        if !defaults[:controller].nil? && !defaults[:action].nil?
          domain = "'" + defaults[:controller].singularize + "#" + defaults[:action]  + "'"
        elsif !defaults[:controller].nil?
          domain = "'" + defaults[:controller].singularize + "'"
        else
          $log.debug "route?"
          domain = nil
        end

        unless domain.nil?
          name = route[:name]
          # url  = route[:path].spec.to_s
          url  = route[:path].to_s

          # Regexp
          # '(?-mix:^PUT$)'    => PUT
          # (?-mix:^GET|POST$) => GET|POST
          # list = route[:verb].to_s.scan(/\^(\S+)\$/)[0]
          # list = [''] if list.nil?
          list = [route[:verb].to_s]
          list << name
          list << url

          #  devise/session#new => devise:session#new
          domain2 = domain.gsub('/', ':')
          map +=  "  #{domain2.rjust(30)} =>  #{list},\n"
        end
      end

      map +=  "}\n"
      return map
    end

    #  'rails:info#index' =>  ["GET", "rails_info", "/rails/info(.:format)"],
    def get_map_old
      map  = ''
      map += "$route_map = {  # new format 20130725\n"
      @raw_route_map.each do |route|
        reqs = route[:reqs]
        c = reqs[:controller]
        a = reqs[:action]
        domain = "'" + c + "#" + a + "'"
        list = [route[:verb]]
        list << route[:name]
        list << route[:path]
        map +=  "  #{domain.rjust(30)} =>  #{list},\n"
      end
      map +=  "}\n"
      return map
    end

    def print
      map = get_map
      puts map
    end

    def save(filename)
      open(filename, "w") do |f|
        f.write "# RailroadMap abstraction map file\n"
        unless @raw_route_map.nil?
          # Raw map
          f.write "\n"
          f.write "# same with rake routes\n"
          map = get_map
          f.write map
        end

        # TODO: automatically set
        f.write "# Ruby code to abstracted expression (B method)\n"
        f.write "$map_guard = {\n"
        f.write "  '' => '',"
        f.write "}\n"
        f.write "# TODO CFRF automatic?\n"
        f.write "$map_guard_by_block = {\n"
        f.write "  '' => '',"
        f.write "}\n"
        f.write "# Actions at block\n"
        f.write "$map_action = {\n"
        f.write "  '' => '',"
        f.write "}\n"
        f.write "# Variables\n"
        f.write "$map_variable = {\n"
        f.write "  'TODO' => 'TODO',"
        f.write "}\n"
        f.write "# SETS in B model\n"
        f.write "$map_bset_types = {\n"
        f.write "  '' => '',"
        f.write "}\n"
        f.write "# EOF\n"
      end # do
    end
  end
end
