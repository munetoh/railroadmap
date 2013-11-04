# -*- coding: UTF-8 -*-

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
  #  3rd gurad       => decide conditions        ---- rails/abstraction.rb
  #
  class Transition
    # 1st
    # TODO: arg?
    def initialize(type, src_id, dst_id, dst_hint, guard)
      @index    = -1  # 20130802 added
      @src_id   = src_id
      @dst_id   = dst_id
      @dst_hint = dst_hint  # hold AST as hint
      @type     = type    # link_to, submit, render, etc
      @subtype  = type # TODO: nil  # actial command name
      @filename = []
      @count    = 0
      @block    = nil
      # TODO
      @guard = guard
      @guard_type = nil
      @guard_ruby = nil
      @guard_abst = nil  # Abstracted HTML5
      @guard_add = nil  # Last one, set by manual
      @action = nil
      @origin = 'unknown'  # Code/Auto/Manual
      # Submit with variables, set by ast.rb
      @variables = []
      # text of Link or Button
      @title = nil
      # text passed to next page
      @messages = nil
      # Valid or Invalid?
      @invalid = false
      @invalid_type = ''
      # Navigation error, bad condition -> secuity  error
      @nav_error = false
      @id = 'T_' + @src_id + '#' + @count.to_s

      # Flags for security guard
      # Authentication
      #   Devise
      #     user_signed_in? == true
      # Authorization
      #   CanCan
      #     can? :update, @article
      #   The_Role
      #     @user.has_role?(:apptypes:index)
      # If guard has authorization check, set used filters here
      # @authorization = nil          # obsolete
      @authentication_filter = nil   # Use this
      @authorization_filter = nil   # Use this

      # if DST requires authorization set TBD here
      @authorization_req = nil

      # SRC DST policy ckeck
      @inconsistent_policy = false

      # Dashboard
      # strings for Dashboard (and HTML)
      # TODO: migrate from output/table.rb -> setup4dashboard()
      @db_id = 0
      @db_src = ''
      @db_dst = ''
      @db_type = ''
      @db_guard = ''
      @is_unclear_dst = false
      @is_unclear_guard = false
      @db_src_policy = ''
      @db_dst_policy = ''

      # Security check
      @trace_count = 0

      # comments
      @comment = ''

    end
    attr_accessor :index, :id, :filename, :count, :src_id, :dst_id, :dst_hint, :type, :subtype, :title, :messages, :block,
                  :origin,
                  :guard, :action, :guard_abst, :guard_add,
                  :variables, :invalid, :invalid_type, :nav_error,
                  #:authorization, :authorization_req,
                  :db_src, :db_dst, :db_type, :db_guard, :db_id,
                  :trace_count,
                  :is_unclear_dst, :is_unclear_guard,
                  :comment,
                  :db_src_policy, :db_dst_policy, :inconsistent_policy,
                  :authentication_filter, :authorization_filter

    def inc
      @count += 1
      @id = 'T_' + @src_id + '#' + @count.to_s
      # inc recursively
      inc unless $abst_transitions[@id].nil?
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

    def add_message(type, message)
      @messages = [] if @messages.nil?
      @messages << [type, message]
    end

    #
    # print table
    #
    def print
      src = @src_id + '[' + @count.to_s + ']'

      filename = ''
      filename = @filename if $verbose > 1

      guard = @block.condition_success  unless @block.nil?
      guard = "[block id=#{@block.id}]"     if guard.nil?

      guard_abst = @block.abst_condition_success unless @block.nil?
      guard_abst = ''                                if guard_abst.nil?

      if @type == 'link_to'
        type = "link_to(#{@title})"
      elsif @type == 'submit'
        type = "submit(#{@title})"
      else
        type = @type
      end

      if @dst_id.nil?
        hint = to_ruby(@dst_hint) # Sorcerer.source(@dst_hint)
        puts "    #{type.ljust(30)} #{src.ljust(33)} -> hint[#{hint.ljust(30)}] if (#{guard})  #{filename}"
      else
        puts "    #{type.ljust(30)} #{src.ljust(33)} -> #{@dst_id.ljust(30)} #{guard.ljust(40)} #{guard_abst.ljust(40)} #{filename}"
      end
    end

    # Graphviz
    def png_set_color(e, type)
      e.set do |_e|
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
        if @label == "error"
          _e.color = "crimson"
          _e.fontcolor = "crimson"
        end
      end # do
    end

    # TODO: move to output/graphviz
    # Graphviz
    def graphviz(oGraph, c0, c1, c2, c3, c4)
      return if @src_id.nil? || @dst_id.nil?
      return if @count > 1 # TODO: eliminate dupulicate trans

      guard = @block.condition_success unless @block.nil?
      guard = "unknown"                    if guard.nil?

      if @title.nil?
        title = ''
      else
        title = "#{@title}"
      end
      @label = @type + '(' + title + ')\n' + guard  + '\n' + @block.id

      if (@src_id =~ /^V_/) && (@dst_id =~ /^V_/)
        # V to V  form
        src_id = @src_id + '_inbound'
        dst_id = @dst_id + '_inbound'

      elsif (@src_id =~ /^V_/) && (@dst_id =~ /^C_/)
        src_id = @src_id + '_inbound'
        dst_id = @dst_id

        c2.add_node(dst_id) if $graphviz_with_rank
      elsif (@src_id =~ /^C_/) && (@dst_id =~ /^V_/)
        src_id = @src_id
        dst_id = @dst_id + '_outbound'
        c2.add_node(src_id) if $graphviz_with_rank
        c4.add_node(dst_id) if $graphviz_with_rank
      elsif (@src_id =~ /^C_/) && (@dst_id =~ /^C_/)
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
      e = oGraph.add_edge(src_id, dst_id, label: @label)
    end

    # Dashboard
    # TODO: call def -> variable -> navmodel.erb
    # return 1 of trans has any unclear
    # TODO: migrate from table.rb
    def setup4dashboard
      # DST
      count = 0
      count += 1 if @is_unclear_dst == true
      # Guard
      count += 1 if @is_unclear_guard == true
      count += 1 if @inconsistent_policy == true

      return count
    end

    # Json
    def to_json(*a)
      {
        "json_class" => self.class.name,
        "filename"   => filename,
        "src id"     => @src_id,
        "dst id"     => @dst_id,
        "data"       => { "string" => @string, "number" => @number }
      }.to_json(*a)
    end
  end
end
