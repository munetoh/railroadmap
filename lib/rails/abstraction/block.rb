require 'sorcerer'

#gem "ruby-graphviz"
require "graphviz"

module Abstraction

  #############################################################################
  # Hold a block structure (tree) in the state
  # e.g.
  #                                      cond         exit   ID
  #  --------------------------------------------------------
  #  root                                                    0
  #       - [0]if A                      A                   0-0
  #                   - [0] if  B        A & B               0-0-0
  #                   - [1] elsif C      A & !B & C          0-0-1
  #                   - [2] else         A & !B & !C    y    0-0-2
  #         [1]else                      !A                  0-1
  #                                                          0 (?) if any exit exist before, so !(exit cond) = !(A & !B & !C)
  #
  class Block
    def initialize
      @cond = nil  # AST      
      @exit = false
      @type = nil
      @next = nil
      @parent = nil
      @childln = []
      @others = []
      
      @condition = nil
      @condition_success = nil
      @condition_fail = nil

      @abst_condition = nil
      @abst_condition_success = nil
      @abst_condition_fail = nil
            
      @level = 0
      @filename = nil
      @id = nil # $state.id + '_B'
    end
    attr_accessor :cond, :exit, :type, :id, :parent, :level, :filename,
      :condition, :condition_success, :condition_fail, 
      :abst_condition, :abst_condition_success, :abst_condition_fail
    
    # TODO
    def debug(msg)
      puts msg if $debug
    end
    
    
    def add_child(type, cond, exit)
      debug "SM DEBUG GUARD add_child #{type} "
      b = Block.new
      b.cond = cond
      b.exit = exit
      b.type = type
      b.level = @level + 1
      
      case type
      when 'do'
        b.id = self.id + '_D'
      else
        b.id = self.id + '_B'
      end
      
      b.parent = self
      @childln << b
      b      
    end
    
    def add(type, cond, exit)
      debug "SM DEBUG GUARD add_child #{type} "
      b = Block.new
      b.cond = cond
      b.exit = exit
      b.type = type
      b.id = self.id + (@others.size + 1).to_s
      @others << b
      
      b
    end    
    
    
    def get_variable(scope, name)
      $abst_variables.each do |n,v|
        dm = v.domain.split('#')
        case dm.size
        when 1
          # Model?
          return v if name == dm[0]
        when 2
          # model attribute
          return v if name == dm[1]
        when 3
          # controller
          return v if name == dm[3]
        else
          p dm
        end
      end
      nil      
    end
    

    # Dataflow
    # hint is text  - TODO or AST?
    def add_dataflow(src_id)
      d = Abstraction::Dataflow.new('control', src_id, nil, @id, nil, nil)
      #d.filename << @filename
      
      if $abst_dataflows[d.id] != nil then
        d.inc          
      end 
      $abst_dataflows[d.id] = d
      debug "add_dataflow control #{d.id}"
      d
    end

    # 
    # Complete Conditions
    #  call this 
    #
    #  tcond      : parents condition
    #  guard2abst : guard(ruby) to abst(ruby?)  hash table
    #
    # TODO AST -> variable and value (symbolic set?)
    def complete_condition(tcond, abst_tcond, guard2abst, guard2abst_byblk)
      # this level
      
      raise "guard2abst is nil" if guard2abst == nil
      raise "guard2abst is nil" if guard2abst_byblk == nil
      #raise "$abstmap_guard is nil" if $abstmap_guard.size == 0
      
      # AST -> variable
      if @cond == nil then
        # no condition
        cond_ruby = nil
      else
        # remove ',' and space
        cond_ruby = Sorcerer.source(@cond).gsub(',','').gsub(' ', '')
      end
      
      # TODO variable == value
      if cond_ruby =~ /(\w+)==(.+)/ then
        cond_ruby = $1
        should = $2
        debug "complete_condition #{cond_ruby} #{should}"
      else
        debug "complete_condition #{cond_ruby}"
        should = 'true'
      end
      
      # block type
      case @type
      when 'do'
        if cond_ruby =~ /(\w+).each/ then
          cond_ruby = $1
        end
        @condition = "#{cond_ruby}.size > 0"
      when 'if'
        @condition = "#{cond_ruby} == #{should}"
      when 'elsif'
        @condition = "#{cond_ruby} == #{should}"
      when 'else'
        @condition = nil
      else
        @condition = nil
      end
      
      # Abstraction
      @abst_condition = guard2abst[@condition]
      if @abst_condition == nil
        @abst_condition = @condition
        $log.debug "complete_condition, no abstraction, keep #{@condition}"
      else
        $log.debug "complete_condition abstraction(#{@condition})  =>#{@abst_condition}"
      end
      
      @abst_condition2 =  guard2abst_byblk[@id]
      if @abst_condition2 == nil
        # no def
        #puts "cond2 no cond def #{@id}"
      elsif @abst_condition != nil
        # Overlap
        #puts "cond2 TODO overlap #{@abst_condition} #{@abst_condition2} def #{@id}"
      else
        # Use block abst
        #puts "cond2 use #{@abst_condition2} def #{@id}" 
        @abst_condition = @abst_condition2
        if @condition == nil
          # id ruby cond is missing, set abst to ruby
          @condition = @abst_condition
        end
      end
      
      
      # Lookup v => dataflow
      #  DC_hoge  Variable -> block
      vo = get_variable(nil, cond_ruby)
      if vo != nil then
        debug "complete_condition HIT"
        add_dataflow(vo.id)
      end
      
      
      # conditions
      if tcond == nil then
        # no previous condition
        if  @condition != nil then
          # place the first condition 
          @condition_success = '(' + @condition + ')'
          @condition_fail = 'not (' + @condition + ')'
          @abst_condition_success = '(' + @abst_condition + ')'
          @abst_condition_fail = 'not (' + @abst_condition + ')'
        else
           # no condition
           @condition_success = nil
        end
      else
        # previous condition exist
        if  @condition != nil then
          # concatinate conditions
          @condition_success = tcond + ' and (' + @condition + ')'
          @condition_fail = tcond + ' and not (' + @condition + ')'
          @abst_condition_success = abst_tcond + ' and (' + @abst_condition + ')'
          @abst_condition_fail = abst_tcond + ' and not (' + @abst_condition + ')'
        else
          # else?
          @condition_success = tcond
          @abst_condition_success = abst_tcond
        end
      end
      
      # recursive calls
      
      # trace chain from root      
      @childln.each do |b|
        b.complete_condition(@condition_success, @abst_condition_success, guard2abst, guard2abst_byblk)
      end
            
      # trace ELSIF ELSE
      @others.each do |b|        
        b.complete_condition(@condition_fail, @abst_condition_fail, guard2abst, guard2abst_byblk)
        @condition_fail = b.condition_fail
        @abst_condition_fail = b.abst_condition_fail
      end
      
      #p @abst_condition_success
    end
    
    
    #
    # print
    #
    def print(indent_level)
      ind = ''
      
      if cond != nil then
        ruby = Sorcerer.source(cond)
      else
        ruby = 'NA'
      end
      
      code = "#{ind.rjust(indent_level)}#{type} #{ruby}"
      
      puts "  #{id.ljust(40)} |#{code.ljust(60)}  - cond = [#{@condition_success}], has #{@childln.size} childln"
      puts "                                                                                                    - cond(abst) = [#{@abst_condition_success}]"
      
      @childln.each do |b|
        b.print(indent_level + 1)
      end
      
      @others.each do |b|
        b.print(indent_level)
      end
    end
  end
end