module Abstraction
  #############################################################################
  # Transition between state/variable
  #
  #  Type         src/dst           guard
  #  ------------------------------------------
  #  GET          V->C              select
  #  POST         V->C              select
  #  -----------------------------------------------
  #  redirect_to  C->C              cond(variables)
  #  render       C->V              cond(variables)
  #  -----------------------------------------------
  #  create       V->C, C->S
  #  read         S->C,      S->V
  #  update       V->C, C->S
  #  delete             C->S
  #  ------------------------------
  #
  #  1st parse code  => set src and dst (or hint of dst) 
  #      ID T_src_render_path?
  #  2nd adjistment  => check and decide the path
  #  3rd gurad       => decide conditions
  #
  class Transition
    # 1st
    # TODO arg?
    def initialize(type, src_id, dst_id, dst_hint, guard)
      @src_id = src_id
      @dst_id = dst_id
      @dst_hint = dst_hint  # hold AST as hint
      @type = type  # link_to, submit, render, etc
      @filename = []
      @count = 0
      @block = nil
      # TODO
      @guard = guard
      @guard_type = nil
      @guard_ruby = nil
      @guard_abst = nil 
      @action = nil
      
      # Submit with variables, set by ast.rb
      @variables = []
      
      # text of Link or Button 
      @title = nil
      
      # Valid or Invalid?
      @invalid = false
      
      @id = 'T_' + @src_id + '#' + @count.to_s
    end
    attr_accessor :id, :filename, :count, :src_id, :dst_id, :dst_hint, :type, :title, :block,
    :guard, :action, :guard_abst,
    :variables, :invalid
    
    def inc
      @count += 1
      @id = 'T_' + @src_id + '#' + @count.to_s
      
      # recursive xhexk
      if $abst_transitions[@id] != nil then
        self.inc          
      end       
    end
    
    # 2nd
    
    
    # 3rd# AST-> Ruby formula
    
    def to_ruby(sexp)
      begin
        Sorcerer.source(sexp) 
      rescue => e
        p e
        'UNKNOWN'
      end
    end

    
    #
    # print table
    #
    def print      
      src = @src_id + '[' + @count.to_s + ']'
      
      filename = ''
      filename = @filename if $verbose > 1
      
      guard = @block.condition_success if @block != nil
      if guard == nil
        guard = "[block id=#{@block.id}]"
      end
      
      guard_abst = @block.abst_condition_success if @block != nil
      if guard_abst == nil
        guard_abst = ''
      end
      
      
      if @type == 'link_to' then
        type = "link_to(#{@title})"
      elsif @type == 'submit' then
        type = "submit(#{@title})"
      else
        type = @type
      end


      if @dst_id != nil then        
        puts "    #{type.ljust(30)} #{src.ljust(33)} -> #{@dst_id.ljust(30)} #{guard.ljust(40)} #{guard_abst.ljust(40)} #{filename}"
      else
        hint = to_ruby(@dst_hint) # Sorcerer.source(@dst_hint) 
        puts "    #{type.ljust(30)} #{src.ljust(33)} -> hint[#{hint.ljust(30)}] if (#{guard})  #{filename}"
      end

    end
    
    
    # Graphviz
    def png_set_color(e, type)
      e.set { |_e|
        case type  
        when "redirect_to"
          _e.color = "cyan4"
          _e.fontcolor = "cyan4"
          _e.weight = "1"
          _e.headport = "n"
          _e.tailport = "s"
        when "link_to" 
          _e.color = "darkgreen"
          _e.fontcolor = "darkgreen"
          _e.weight = "1"
          _e.headport = "n"
          _e.tailport = "s"
        when "submit" 
          _e.color = "goldenrod4"
          _e.fontcolor = "goldenrod4"
          _e.weight = "5"
          _e.headport = "n"
          _e.tailport = "s"
        when "layout" 
          _e.color = "grey43"
          _e.fontcolor = "grey43"
          _e.arrowsize = "0.1"
          _e.weight = "10"
        when "render" 
          _e.color = "cyan4"
          _e.fontcolor = "cyan4"
          _e.arrowsize = "1"
          _e.weight = "5"
          _e.headport = "n"
          _e.tailport = "s"
        else
        end
        
        # ERROR => RED
        if @label == "error" then
          _e.color = "crimson"
          _e.fontcolor = "crimson"
        end
      }
    end
    
    
    # TODO move to output/graphviz
    # Graphviz
    #
    def graphviz(oGraph, c0, c1, c2, c3, c4)
 
      if @src_id == nil or @dst_id == nil then
        return
      end
      
      if @count > 1 then
        # TODO eliminate dupulicate trans
        return
      end
      
      guard = @block.condition_success if @block != nil
      if guard == nil
        #guard = "[block id=#{@block.id}]"
        guard = "unknown"
      end
      
      # 
      if @title == nil then
        title = ''
      else
        title = "#{@title}"
      end
      @label = @type + '(' + title + ')\n' + guard  + '\n' + @block.id
      #pp @label
      
      
      if (@src_id =~ /^V_/) and (@dst_id =~ /^V_/) then
        # V to V  form         
        src_id = @src_id + '_inbound'
        dst_id = @dst_id + '_inbound'
        
        #c0.add_node(src_id)
        #c1.add_node(dst_id)
        
      elsif (@src_id =~ /^V_/) and (@dst_id =~ /^C_/) then
        src_id = @src_id + '_inbound'
        dst_id = @dst_id
        
        #c1.add_node(src_id)
        c2.add_node(dst_id) if $graphviz_with_rank
        
      elsif (@src_id =~ /^C_/) and (@dst_id =~ /^V_/) then
        src_id = @src_id
        dst_id = @dst_id + '_outbound'
        c2.add_node(src_id) if $graphviz_with_rank
        c4.add_node(dst_id) if $graphviz_with_rank
        
      elsif (@src_id =~ /^C_/) and (@dst_id =~ /^C_/) then
        # redirect
        src_id = @src_id
        dst_id = @dst_id
        c2.add_node(src_id) if $graphviz_with_rank
        c3.add_node(dst_id) if $graphviz_with_rank
      else
        src_id = @src_id
        dst_id = @dst_id
      end

      # draw
      e = oGraph.add_edge(src_id, dst_id, :label => @label)
      

      
      #  puts "GraphvizEdge : #{@src_id} -> #{@dst_id}"
    end
    
  end
end