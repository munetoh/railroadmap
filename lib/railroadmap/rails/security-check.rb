# -*- coding: UTF-8 -*-
# Security check
# TODO: update, cancan => any
#
# 20131110 cleanup v010 code

module Rails
  # Security check
  class SecurityCheck
    def initialize
      @securitycheck = {}
      scan_info      = {}
      $warning ||= Warning.new
      scan_info['app_path'] = $approot_dir
      scan_info['number_of_states'] = $abst_states.size
      scan_info['number_of_transitions'] = $abst_transitions.size

      puts "    Static security test (PEP@controller check)"
      # PEP - Controller
      check_missing_authentication
      check_missing_authorization

      if $warning.count > 0
        puts "    Static security test (PEP@view check, Navigation error) - SKIP"
        puts "    Static security test (dataflow check) - SKIP"
      else
        # PEP - View
        puts "    Static security test (PEP@view check, Navigation error)"
        check_inconsistent_authentication
        check_inconsistent_authorization
        # DF in and out
        puts "    Static security test (dataflow check)"
        check_inconsistent_dataflow
      end

      # Show result
      if $warning.count > 0
        print "\e[31m"  # red
        puts "    warnings : #{$warning.count} (access control)"
      else
        print "\e[32m"  # green
        puts "    warnings : #{$warning.count}  (access control)"
      end
      print "\e[0m" # reset

      # Prepare for JSON out
      scan_info['security_warnings'] = $warning.count
      @securitycheck['scan_info'] =  scan_info
      @securitycheck['warnings'] =  $warning.warnings  # Array
    end

    #--------------------------------------------------------------------------
    # Check missing authentication
    def check_missing_authentication_v010
      # requirement error (req_error) flag
      #
      # default => false
      # lib/rails/requirement.rb => set true
      $abst_states.each do |n, s|
        if s.req_error
          w = Hash.new
          w['warning_type'] = 'Missing authentication'
          w['message'] = "No authentication for #{s.domain}"  # TODO: get URL also
          w['file'] = s.filename
          w['line'] = nil
          w['code'] = nil
          w['location'] = nil
          w['user_input'] = nil
          w['confidence'] = 'Medium'    # Weak Medium High
          $warning.add(w)
        end
      end
    end

    def print_pep_error(state, type)
      print "\e[31m" # Red
      puts "      Missing PEP(#{type})  #{state.id}"
      puts "---"
      puts "$assets_mask_policies = {"
      puts "  '#{state.id}' => {"
      if state.code_policy.is_authenticated == false
        puts "    is_authenticated: false,"
      elsif state.code_policy.is_authenticated == true
        puts "    is_authenticated: true,"
        if state.code_policy.is_authorized == false
          puts "    is_authorized: false,"
        elsif state.code_policy.is_authorized == true
          puts "    is_authorized: true,"
        else
          puts "    is_authorized: true,   # TODO: clarify"
        end
      else
        puts "    is_authenticated: true, # TODO: clarify"
        puts "    is_authorized: true,    # TODO: clarify"
      end
      puts "    level: 0,  # Public"
      puts "    color: 'green'"
      puts "  },"

      puts "}"
      puts "---"

      print "\e[0m" # reset
    end

    def check_missing_authentication
      $abst_states.each do |n, s|
        if s.type == 'controller' && !s.req_policies[0].nil? && s.routed
          if s.req_policies[0].is_authenticated
            if s.code_policy.is_authenticated
              # Good
            else
              # No PEP
              s.req_error = true
              type = 'Missing authentication'
              msg = "[Req:O, Code:X] No authentication for #{s.domain}"  # TODO: get URL also
            end
          else
            if s.code_policy.is_authenticated
              # No Req
              s.req_error = true
              type = 'Missing authentication'
              msg = "[Req:X, Code:O] No authentication for #{s.domain}"  # TODO: get URL also
            else
              # God public
            end
          end
        end

        if s.req_error
          w = Hash.new
          w['warning_type'] = type
          w['message'] = msg
          w['file'] = s.filename
          w['line'] = nil
          w['code'] = nil
          w['location'] = nil
          w['user_input'] = nil
          w['confidence'] = 'High'    # Weak Medium High
          $warning.add(w)

          print_pep_error(s,  'authentication')
        end
      end
    end

    #--------------------------------------------------------------------------
    # Check authorization at controller
    def check_missing_authorization
      $abst_states.each do |n, s|
        if s.type == 'controller' && !s.req_policies[0].nil? && s.routed
          if s.req_policies[0].is_authorized
            if s.code_policy.is_authorized
              # Good
            else
              # No PEP
              s.req_error = true
              type = 'Missing authorization'
              msg = "[Req:O, Code:X] No authorization for #{s.domain}"  # TODO: get URL also
            end
          else
            if s.code_policy.is_authorized
              # No Req
              s.req_error = true
              type = 'Missing authorization'
              msg = "[Req:X, Code:O] No authorization for #{s.domain}"  # TODO: get URL also
            else
              # God public
            end
          end
        end

        if s.req_error
          w = Hash.new
          w['warning_type'] = type
          w['message'] = msg
          w['file'] = s.filename
          w['line'] = nil
          w['code'] = nil
          w['location'] = nil
          w['user_input'] = nil
          w['confidence'] = 'High'    # Weak Medium High
          $warning.add(w)

          print_pep_error(s, 'authorization')
        end
      end
    end

    #--------------------------------------------------------------------------
    # Check authentication authorization at view
    # Here, we trust PEP@Controller code (consistent w/ req)
    def print_nav_error(trans, ssl, dsl)
      print "\e[36m" # Cyan
      puts "      Navigation error? #{trans.src_id}[lv:#{ssl}] => #{trans.dst_id}[lv:#{dsl}]"
      print "\e[0m" # reset
    end

    def check_inconsistent_authentication
      $abst_transitions.each do |n, t|
        unless t.dst_id.nil?
          ss = $abst_states[t.src_id]
          ds = $abst_states[t.dst_id]
          if ss.type == 'view' && !ds.nil? && ds.code_policy.is_authenticated
            # PEP exist@controller

            if t.authentication_filter
              # Has PEP
              # $log.error "check_inconsistent_authentication #{t.id} has PEP"
            else
              # No PEP
              # same domain?
              if ss.req_policies.size == 1
                # single req policy
                if ss.req_policies[0].is_authenticated
                  # $log.error "check_inconsistent_authentication #{t.id} no PEP but auth state"
                else
                  # $log.error "check_inconsistent_authentication #{t.id} no PEP - ERROR"
                  t.nav_error = true
                  ss.nav_error  = true
                  w = Hash.new
                  w['warning_type'] = 'Missing view side authentication check'
                  w['message'] = "View #{ss.domain} has NO-authentication check, but enforcement at controller side #{ds.domain}."
                  w['file'] = t.filename # TODO: controller
                  w['line'] = nil
                  w['code'] = nil
                  w['location'] = nil
                  w['user_input'] = nil
                  w['confidence'] = 'Weak'    # Weak Medium High
                  $warning.add(w)

                  print_nav_error(t, ss.code_policy.level, ds.code_policy.level)
                end
              else
                # $log.error "check_inconsistent_authentication #{t.id} no PEP many pol - TODO"
              end
            end
          end
        end
      end
    end

    def check_inconsistent_authorization
      $abst_transitions.each do |n, t|
        unless t.dst_id.nil?
          ss = $abst_states[t.src_id]
          ds = $abst_states[t.dst_id]
          if ss.type == 'view' && !ds.nil? && ds.code_policy.is_authorized
            # PEP exist@controller

            # update filter check
            # 20131109 move to PDP.compleate_pep_assignment
            # t.authorization_filter = t.block.get_authorization_filter

            if t.authorization_filter
              # Has PEP
              # $log.error "check_inconsistent_authorization #{t.id} has PEP"
            else
              # No PEP
              # same domain?
              if ss.req_policies.size == 1
                # single req policy
                if ss.req_policies[0].is_authorized
                  # $log.error "check_inconsistent_authorization #{t.id} no PEP but auth state"
                else
                  # $log.error "check_inconsistent_authorization #{t.id} to #{ds.id} no PEP - ERROR"
                  # p t.guard
                  t.nav_error = true
                  ss.nav_error  = true
                  w = Hash.new
                  w['warning_type'] = 'Missing view side authorization check'
                  w['message'] = "View #{ss.domain} has NO-authorization check, but enforcement at controller side #{ds.domain}."
                  w['file'] = t.filename # TODO: controller
                  w['line'] = nil
                  w['code'] = nil
                  w['location'] = nil
                  w['user_input'] = nil
                  w['confidence'] = 'Weak'    # Weak Medium High
                  $warning.add(w)

                  print_nav_error(t, ss.code_policy.level, ds.code_policy.level)
                end
              else
                # $log.error "check_inconsistent_authorization #{t.id} no PEP many pol - TODO"
              end
            end
          end
        end
      end
    end

    #---------------------------------------------------------------------------
    def print_df_error(df, ssl, dsl)
      print "\e[35m" # purpule
      puts "      suspicuous dataflow H2L #{df.src_id}[lv:#{ssl}] => #{df.dst_id}[lv:#{dsl}]"
      print "\e[0m" # reset
    end

    def check_inconsistent_dataflow
      $abst_dataflows.each do |n, df|
        if df.type == 'out' && !df.src_id.nil? && !df.dst_id.nil?
          ss = $abst_variables[df.src_id]
          ds = $abst_states[df.dst_id]

          unless ss.nil? || ds.nil?
            # $log.error "check_inconsistent_dataflow HIT #{ss.id} #{ds.id}"
            unless ss.code_policy.nil? || ds.code_policy.nil?
              unless ss.code_policy.level.nil? || ds.code_policy.level.nil?
                # $log.error "check_inconsistent_dataflow HIT #{ss.code_policy.level} VS #{ds.code_policy.level}"
                if ss.code_policy.level > ds.code_policy.level
                  # $log.error "check_inconsistent_dataflow HIT #{ss.code_policy.level} => #{ds.code_policy.level}"

                  df.df_error = true
                  ds.df_error  = true
                  w = Hash.new
                  w['warning_type'] = 'High to low dataflow'
                  w['message'] = "View #{ds.domain} has high to low dataflow"
                  w['file'] = ds.filename # TODO: controller
                  w['line'] = nil
                  w['code'] = nil
                  w['location'] = nil
                  w['user_input'] = nil
                  w['confidence'] = 'Weak'    # Weak Medium High
                  $warning.add(w)

                  print_df_error(df, ss.code_policy.level, ds.code_policy.level)
                end
                # set policy level to DF
                df.src_level = ss.code_policy.level
                df.dst_level = ds.code_policy.level
              end
            end
          end
        end
      end
    end

    #---------------------------------------------------------------------------------
    # JSON out
    def save_json(filename)
      File.open(filename, "w") do |f|
        f.write(JSON.pretty_generate(@securitycheck))
      end
    end
  end
end
