module Abstraction
  #############################################################################
  # Dataflow
  #
  #  type           id
  #  -----------------------------------------
  #  out  (M->V)    DI_dst_id[n]   
  #  in (V->C->M)   DO_src_id[n]
  #  controll       DC_dst_id[n]   TODO 
  #
  class Dataflow
    # 1st
    # TODO arg?
    def initialize(type, src_id, src_hint, dst_id, dst_hint, guard)
      @src_id = src_id
      @src_hint = src_hint  # text
      @dst_id = dst_id
      @dst_hint = dst_hint  # text
      @type = type
      @type2 = nil
      @filename = []
      @count = 0
      @src_block = nil
      @dst_block = nil

      # TODO
      @guard = guard
      @guard_type = nil
      @guard_ruby = nil
      
      # text of Link or Button 
      @title = nil
      
      set_id
    end
    attr_accessor :id, :filename, :count, :src_id, :dst_id, :dst_hint, :type, :type2, :title,
    :src_block, :dst_block, :guard
    
    
    def set_id
      if @type == 'label' then
        @type2 = 'out'
        # C->V(known)
        @id = 'DO_' + @dst_id + '#' + @count.to_s
      elsif type == 'control' then
        @type2 = 'control'
        @id = 'DC_' + @dst_id + '#' + @count.to_s
      else
        @type2 = 'in'
        # V(known)->C
        @id = 'DI_' + @src_id + '#' + @count.to_s
      end     
    end
    
    def inc
      @count += 1
      set_id
      
      # recursive xhexk
      if $abst_dataflows[@id] != nil then
        self.inc          
      end       
    end
    
    
    ###########################################################################
    # TODO cleanup the df - del dup 
    #
    
    
    ###########################################################################
    # Print
    #
    def print      
      src_id = @src_id || 'TBD'
      dst_id = @dst_id || 'TBD'
      filename = ''
      filename = @filename if $verbose > 2
      
      if $verbose > 0 then
        if @type2 == 'out' then  
          # C -> V      
          puts "    out  #{@type.ljust(17)}                                      #{src_id.ljust(30)} -> #{dst_id.ljust(20)} #{@guard} #{filename}"
          puts "                                                                                                  #{dst_block.ljust(20)}"
        elsif @type2 == 'in' then
          # V ->C 
          puts "    in   #{@type.ljust(17)}   #{src_id.ljust(30)}  -> #{dst_id.ljust(30)}                                  #{@guard} #{filename}"
          puts "                             #{src_block.ljust(30)}  "
        elsif @type2 == 'control' then
          puts "    ctrl #{@type.ljust(17)}                                      #{src_id.ljust(30)} -> #{dst_id.ljust(30)}                                    #{@guard} #{filename}"
        end
        #else
          #hint = Sorcerer.source(@dst_hint) 
        #  puts "    #{@type.ljust(17)} #{src.ljust(33)} -> [#{hint.ljust(30)}] if (#{@guard})  #{@filename}"
        #end
      #else
      #  if @dst_id != nil then        
      #    puts "    #{@type.ljust(17)} #{src.ljust(33)} -> #{@dst_id.ljust(30)} #{@guard}"
      #  else
      #    #hint = Sorcerer.source(@dst_hint) 
      #    puts "    #{@type.ljust(17)} #{src.ljust(33)} -> [#{hint.ljust(30)}] if (#{@guard})"
      #  end
      end
    end
    
    
    
    ###########################################################################
    #
    #
    def graphviz(oGraph, c0, c1, c2, c3, c4)
 
      if @src_id == nil or @dst_id == nil then
        return
      end
      
      #if @count > 0 then
      #  return
      #end
      
      #guard = @block.condition_success if @block != nil
      #if guard == nil
      #  guard = "[block id=#{@block.id}]"
      #end
      guard = 'TBD'
      
      #@label = @type + '\n' + guard
      @label = @id
      #pp @label
      
      if @type2 == 'out' then
        # C -> V    
        #puts "    #{@type.ljust(17)}   #{src_id.ljust(30)} -> #{dst_id.ljust(20)}                                    #{@guard} #{filename}"
        src_id = @src_id
        dst_id = @dst_id + '_outbound'
        c2.add_node(src_id) if $graphviz_with_rank
        c4.add_node(dst_id) if $graphviz_with_rank
      elsif @type2 == 'in' then
        # V -> C
        #puts "    #{@type.ljust(17)}                                     #{src_id.ljust(20)}  -> #{dst_id.ljust(30)} #{@guard} #{filename}"
        src_id = @src_id + '_inbound'
        dst_id = @dst_id 
        c0.add_node(src_id) if $graphviz_with_rank
        c2.add_node(dst_id) if $graphviz_with_rank
      elsif @type2 == 'control' then
        #puts "    #{@type.ljust(17)}   #{src_id.ljust(30)} -> #{dst_id.ljust(30)}                                    #{@guard} #{filename}"
        src_id = @src_id + '_inbound_CTRL'
        dst_id = @dst_id 
        c0.add_node(src_id) if $graphviz_with_rank
        c2.add_node(dst_id) if $graphviz_with_rank
      end
        
  

      # draw
      e = oGraph.add_edge(src_id, dst_id, :label => @label)
      

      
      #  puts "GraphvizEdge : #{@src_id} -> #{@dst_id}"
          
    end
    

  end
  
end