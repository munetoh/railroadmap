#
#
#

module Rails
  class Root
    def initialize
      
    end
  
  
    # ./app exist => add to the path
    def getRootDirsFromGems
      # Get Application root dir and Modules
      hList = Hash.new
      aList = Array.new
      # All gems
      # NOTE: Gem::GemPathSearcher#initialize is deprecated with no replacement. It will be removed on or after 2011-10-01.
      searcher = Gem::GemPathSearcher.new
      list = searcher.init_gemspecs
      
      
      list.each do |spec|
        $log.debug( "spec name : #{spec.name}")
        app_path =  spec.full_gem_path + '/app'
        if File.exists?(app_path)
          if spec.name == 'devise' then
            $log.debug( "use devise!!")
            $use_devise = true
          end
          
          if hList[spec.name] == nil
            # new
            $log.debug( "rails app?")
            hList[spec.name] = [spec.version, spec.full_gem_path]
          else
            # hit, select latest one
            if hList[spec.name][0] < spec.version
              hList[spec.name][0] = spec.version
              hList[spec.name][1] = spec.full_gem_path
            end
          end
        end
      end
      
      # Add this app
      hList['this'] = [nil, Dir.pwd]
      
      # Dir list
      hList.each do |k,v|
        aList.push(v[1])
      end
      aList
    end
  end
end