# -*- coding: UTF-8 -*-
# XSS
#
#  escape <=   =>
#  raw
#
module Rails
  # XSS
  class XSS
    def initialize
      $warning ||= Warning.new
      # set 0 => raw command => inc
      $xss_raw_count = 0
      # flag to indicate RAW
      $xss_raw_region = false
      $xss_raw_files = []
    end

    # Trace M->V(raw), V-M-V(raw) dataflows
    #   table - yellow
    #   DFD   - red line
    #
    #  called at CLI
    def trace_raw
      $log.debug "XSS trace raw"
      # Output
      $abst_dataflows.each do |n1, d1|
        if d1.subtype == 'raw_out'
          if $enable_stdout
            print "\e[31m"  # red
            puts "      #{n1} has raw output."
            print "\e[0m" # reset
          end
          $log.debug "XSS   #{n1} has raw output. check the state that input #{d1.src_id}, output #{d1.dst_id}"

          d1.xss_trace = true
          $abst_states[d1.dst_id].xss_out << d1
          # Input
          in_states = []
          $abst_dataflows.each do |n2, d2|
            if d2.dst_id == d1.src_id
              $log.debug "XSS     #{d2.src_id} ==(#{d2.type})==> #{d1.src_id} ==(raw)==> #{d1.dst_id}"
              d2.xss_trace = true
              $abst_states[d1.dst_id].xss_in << d2
              in_states << d2.src_id
            end
          end

          # add to Warnings
          w = Hash.new
          w['warning_type'] = 'Cross Site Scripting'
          w['message'] = "Unescaped model attribute, path in:#{in_states}->var:#{d1.src_id}->out:#{d1.dst_id}"
          w['file'] = d1.filename # TODO: condblk.filename is nil
          w['file2'] = nil
          w['line'] = nil
          w['code'] = nil
          w['location'] = nil
          w['user_input'] = nil
          # put explicit raw here => programmer should have some intentions => but test
          w['confidence'] = 'High'  # Weak Medium High
          w['hit_state'] = d1.dst_id
          w['hit_variable'] = d1.src_id
          $warning.add(w)
        end
      end

      # Trace C-V(raw_out)
      $abst_transitions.each do |n1, t|
        if !$abst_states[t.dst_id].nil? && $abst_states[t.dst_id].type == 'view'
          v = $abst_states[t.dst_id]
          if $abst_states[t.src_id].type == 'controller'
            c = $abst_states[t.src_id]
            # C-V
            c.test_xss_path << t if v.xss_out.count > 0
          end
        end
      end # trans loop
    end # def
  end # class
end
