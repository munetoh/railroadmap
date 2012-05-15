module Abstraction
  class Map
    def initialize
      @route_map = nil
    end
    
    def setRoutes(map)
      # raw map from app
      @route_map = map
    end
    
    
    
    def newMap(filename)
      open(filename, "w") {|f| 
          f.write "# RailroadMap abstraction map file\n"
          
          
          if @route_map != nil then
            # Raw map
            f.write "\n"
            f.write "# same with rake routes\n"
            f.write "$route_map = [\n"
            @route_map.each do |k,v|
              pathname = "'#{k}'"
              f.write "  #{pathname.rjust(30)} => ['#{v[0]}','#{v[1]}','#{v[2]}','#{v[3]}'],\n"
            end
            f.write "]\n"
            
            # Railroadmap map
            f.write "\n"
            f.write "# for RailroadMap.  pathname in ruby  =>  state id\n"
            f.write "$path2id = {\n"
            @route_map.each do |k,v|
              
              pathname      = "'#{k}'"
              at_pathname   = "'@#{k}'"
              pathname_path = "'#{k}_path'"
              pathname_url  = "'#{k}_url'"
              
              #controller = ActiveSupport::Inflector.singularize(v[0])
              controller = v[0].singularize
              domain   =  controller.gsub('/',':').  + '#' + v[1]
              
              
              idname   = "'C_#{domain}'" 
              
              # TODO 
              if v[1] == 'show'
                f.write "  #{at_pathname.rjust(30)}      => #{idname},\n"
              end
              f.write "  #{pathname.rjust(30)}      => #{idname},\n"
              f.write "  #{pathname_path.rjust(35)} => #{idname},\n"
              f.write "  #{pathname_url.rjust(34)}  => #{idname},\n"
              
              
            end
            f.write "}\n"
            
          end
          
          f.write "# EOF\n"
      }
    end
  end
end