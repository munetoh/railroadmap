# -*- coding: UTF-8 -*-
# 20130829 Be generic, no more swap src/dst
#   command has flags, is_inbound, is_outbound
#   types are in, out, control

#############################################################################
# Dataflow (OLD)
#
#  type        type2    path      id                src_id      dst_id
#  ----------------------------------------------------------------------
#  label       out      M->V      DI_dst_id[n]      variable    state(View)
#  raw_out     out
#  escaped_out out
#  ----------------------------------------------------------------------
#  *           in       V->C->M   DO_src_id[n]      state(View) variable
#  ----------------------------------------------------------------------
#  controll    control            DC_dst_id[n]   TODO: ?
#

module Abstraction
  # Dataflow
  class Dataflow
    # 1st
    # TODO: arg?
    def initialize(type, subtype, src_id, src_hint, dst_id, dst_hint, guard)
      @index     = -1
      @type      = type     # in | control | out
      @subtype   = subtype  # command name, e.g. label etc
      @src_id    = src_id
      @src_hint  = src_hint  # text
      @dst_id    = dst_id
      @dst_hint  = dst_hint  # text
      @filename  = []
      @count     = 0
      @src_block = nil
      @dst_block = nil
      @origin    = 'unknown'  # Code/Auto/Manual
      @comment   = ''
      @title      = nil # text of Link or Button
      @xss_trace = false # flag for XSS trace, raw autput

      @guard      = guard
      @guard_type = nil
      @guard_ruby = nil

      # set dataflow id
      set_id

      # Policy
      @in_policy             = nil
      @variable_policy        = nil
      @out_policy             = nil
      @is_unclear_policy      = false
      @unclear_policy_comment = ""

      @src_level = nil
      @dst_level = nil
      @df_error = false
    end
    attr_accessor :index, :id, :filename, :count, :src_id, :dst_id, :dst_hint, :type, :subtype, :title,
                  :origin, :comment,
                  :src_block, :dst_block, :guard,
                  :xss_trace,
                  :in_policy, :variable_policy, :out_policy,
                  :is_unclear_policy, :unclear_policy_comment, :df_error,
                  :src_level, :dst_level

    def set_id
      # 20130702 added
      @dst_id = 'unknown' if @dst_id.nil?

      if @type == 'out'
        # C->V(known)
        @id = 'DO_' + @dst_id + '#' + @count.to_s
      elsif @type == 'control'
        @id = 'DC_' + @dst_id + '#' + @count.to_s
      elsif @type == 'in'
        @id = 'DI_' + @src_id + '#' + @count.to_s
      # v0.2.0 type = command type, subtype => obsorete
      elsif @type == 'dataflow' && @subtype == 'input'
        @id = 'DI_' + @src_id + '#' + @count.to_s
        $log.error "DF #{@type} #{@subtype} #{src_id} dst_id=#{dst_id} dst_hint=#{dst_hint} g=#{guard}"
      else
        fail "BAD type=#{@type} subtype=#{@subtype}"
      end
    end

    def inc
      @count += 1
      set_id
      # recursive check
      inc unless $abst_dataflows[@id].nil?
    end

    ###########################################################################
    # Print
    def print
      src_id = @src_id || 'TBD'
      dst_id = @dst_id || 'TBD'
      filename = @filename

      if $verbose == 1
        if @type == 'out'
          # C -> V
          puts "    out  #{@type.ljust(17)}                                      #{src_id.ljust(30)} -> #{dst_id.ljust(20)} #{@guard} #{filename}"
          if dst_block.nil?
            puts "TBD"
          else
            puts "                                                                                                  #{dst_block.ljust(20)}"
          end
        elsif @type == 'in'
          # V ->C
          puts "    in   #{@type.ljust(17)}   #{src_id.ljust(30)}  -> #{dst_id.ljust(30)}                                  #{@guard} #{filename}"
        elsif @type == 'control'
          puts "    ctrl #{@type.ljust(17)}                                      #{src_id.ljust(30)} -> #{dst_id.ljust(30)}                                    #{@guard} #{filename}"
        end
      end
    end

    ###########################################################################
    # Obsolete
    def graphviz(oGraph, c0, c1, c2, c3, c4)
      return if @src_id.nil? || @dst_id.nil?

      guard = 'TBD'
      @label = @id
      if @type2 == 'out'
        # C -> V
        src_id = @src_id
        dst_id = @dst_id + '_outbound'
        c2.add_node(src_id) if $graphviz_with_rank
        c4.add_node(dst_id) if $graphviz_with_rank
      elsif @type2 == 'in'
        # V -> C
        src_id = @src_id + '_inbound'
        dst_id = @dst_id
        c0.add_node(src_id) if $graphviz_with_rank
        c2.add_node(dst_id) if $graphviz_with_rank
      elsif @type2 == 'control'
        src_id = @src_id + '_inbound_CTRL'
        dst_id = @dst_id
        c0.add_node(src_id) if $graphviz_with_rank
        c2.add_node(dst_id) if $graphviz_with_rank
      end
      # draw
      e = oGraph.add_edge(src_id, dst_id, label: @label)
      #  puts "GraphvizEdge : #{@src_id} -> #{@dst_id}"
    end
  end
end
