# -*- coding: UTF-8 -*-
# Security check
# TODO: update, cancan => any
#
# 20131110 cleanup v010 code

module Rails
  # Security check
  class SecurityCheck
    def initialize
      @msg = "    Static security test (PEP@controller check)\n"
      @missing_policy_state_count = 0

      @securitycheck = {}
      scan_info      = {}
      $warning ||= Warning.new
      warning_count = $warning.count

      scan_info['app_path'] = $approot_dir
      scan_info['number_of_states'] = $abst_states.size
      scan_info['number_of_transitions'] = $abst_transitions.size

      # global SF
      check_csrf

      # Missing PEP - Controller
      check_missing_authentication
      check_missing_authorization

      if $warning.count > 0 && $enable_stdout
        @msg += "    Static security test (PEP@view check, Navigation error) - SKIP\n"
        @msg += "    Static security test (dataflow check) - SKIP\n"
      else
        # PEP - View
        @msg += "    Static security test (PEP@view check, Navigation error)\n"
        check_inconsistent_authentication
        check_inconsistent_authorization

        # DF in and out
        if $static_dataflow_analysis
          @msg += "    Static security test (dataflow check)\n"
          check_inconsistent_dataflow
        end
      end

      if $req.has_remidiation
        print "\e[31m" # Red
        puts "      missing policy count: #{@missing_policy_state_count}"
        puts "      Add the following discrete policies to railroadmap/requirements.json"
        puts "---"
        $req.print_discrete_requirement
        puts "---"
        print "\e[0m" # reset
      end

      # AC warnings
      $access_control_warning_count = $warning.count - warning_count

      # Show the result to console
      if $enable_stdout
        print @msg
        if $access_control_warning_count > 0
          print "\e[31m" # red
          puts "    warnings : #{$access_control_warning_count} (access control)"
        else
          print "\e[32m" # green
          puts "    warnings : #{$access_control_warning_count}  (access control)"
        end
        print "\e[0m"  # reset
      end

      # Prepare for JSON out
      scan_info['security_warnings'] = $warning.count
      @securitycheck['scan_info'] =  scan_info
      @securitycheck['warnings'] =  $warning.warnings  # Array
    end

    #
    def check_csrf
      if $protect_from_forgery == true
        # OK
        # TODO: check protect_from_forgery OPTIONs
      else
        # NG
        w = {}
        w['warning_type'] = 'Missing CSRF protection'
        w['cwe_id'] = 352
        w['cwe_url'] = 'http://cwe.mitre.org/data/definitions/352.html'
        w['message'] = "Missing CSRF protection"
        w['remidiation'] = "place 'protect_from_forgery' command in application_controller.rb"
        w['file'] = 'app/controllers/application_controller.rb'
        w['line'] = nil
        w['code'] = nil
        w['location'] = nil
        w['user_input'] = nil
        w['confidence'] = 'High'    # Weak Medium High
        $warning.add(w)
      end
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
      fail "$req is missing" if $req.nil?

      print "\e[31m" # Red
      puts "      Missing PEP(#{type})  #{state.id}"
      print "\e[0m" # reset

      @missing_policy_state_count += 1
      $req.add_discrete_requirement(state)
    end

    # code  req
    # ------------------
    # __    pub  ok
    # A_    A_   ok
    # __    A_   ERROR
    # __    AA   ERROR <<
    # AA    AA   ok
    # A_    AA   ERROR
    # _A    AA   ERROR
    # _A    pub   OK
    #
    # routed
    #   nil   no C and V
    #   false not PEP
    #   true  <= check
    def check_missing_authentication
      $abst_states.each do |n, s|
        if s.type == 'controller' && !s.req_policies[0].nil? && s.routed
          if s.req_policies[0].is_authenticated # A_
            if s.code_policy.is_authenticated
              # Good
            else
              # No PEP
              s.req_error = true
              type = 'Missing authentication'
              msg  = "[Req:O, Code:X] No authentication for #{s.domain}"  # TODO: get URL also
            end
          else # pub, __
            if s.code_policy.is_authenticated
              # No Req
              s.req_error = true
              type = 'Missing authentication'
              msg  = "[Req:X, Code:O] No authentication for #{s.domain}"  # TODO: get URL also
            else
              # Good, both req and code are public
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
          print_pep_error(s,  'authentication') if $enable_stdout
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
              # No PEP code
              s.req_error = true
              type = 'Missing authorization'
              msg = "[Req:O, Code:X] No authorization for #{s.domain}"  # TODO: get URL also
            end
          else
            if s.code_policy.is_authorized
              # No Req
              if s.code_policy.is_authenticated
                s.req_error = true
                type = 'Missing authorization'
                msg = "[Req:X, Code:O] No authorization for #{s.domain}"  # TODO: get URL also
              else
                # _A
              end
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
          print_pep_error(s, 'authorization') if $enable_stdout
        end
      end
    end

    #--------------------------------------------------------------------------
    # Check authentication authorization at view
    # Here, we trust PEP@Controller code (consistent w/ req)
    # This is a check at REQ level
    #  V(R:*,C:*)----A--->C(R:*, C:A)    OK
    #  V(R:A,C:*)-------->C(R:*, C:A)    OK
    #  V(R:A,C:*)-------->C(R:*, C:A)
    def print_nav_error(trans, ssl, dsl, type)
      print "\e[36m" # Cyan
      puts "      Navigation error? #{trans.src_id}[lv:#{ssl}] => #{trans.dst_id}[lv:#{dsl}], #{type}"
      print "\e[0m" # reset
    end

    def check_inconsistent_authentication
      $abst_transitions.each do |n, t|
        unless t.dst_id.nil?
          ss = $abst_states[t.src_id]
          ds = $abst_states[t.dst_id]
          no_pep = true
          if ss.type == 'view' && !ds.nil? && ds.code_policy.is_authenticated
            # V->C and C CODE hash PEP
            if t.authentication_filter
              # Trans CODE has authentication check => SKIP
              # $log.error "check_inconsistent_authentication #{t.id} has PEP"
              no_pep = false
            elsif t.authorization_filter
              # Trans CODE has authorization check, authorization include authentication => SKIP
            else
              # Trans CODE has no-PEP
              # same domain?
              if ss.req_policies.size == 0
                # No policy => remidiation
                @missing_policy_state_count += 1
                $req.add_discrete_requirement(ss)
              elsif ss.req_policies.size == 1
                # single req policy
                if ss.req_policies[0].is_authenticated
                  # View REQ is authenticated => SKIP
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

                  print_nav_error(t, ss.code_policy.level, ds.code_policy.level, "missing authentication") if $enable_stdout
                  # pp t
                end
              else
                # multiple REQ policies
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
          no_pep = true
          type = -1
          ss = $abst_states[t.src_id]
          ds = $abst_states[t.dst_id]
          if ss.code_policy.nil?
            ss_code_policy_level = -1
          else
            ss_code_policy_level = ss.code_policy.level
          end
          if ds.nil?
            ds_code_policy_level = -2
            no_pep = false # SKIP
          else
            if ds.code_policy.nil?
              ds_code_policy_level = -1
            else
              ds_code_policy_level = ds.code_policy.level
            end
          end

          if ss.type == 'view' && !ds.nil? && ds.code_policy.is_authorized
            # PEP exist@controller

            # update filter check
            # 20131109 move to PDP.compleate_pep_assignment
            # t.authorization_filter = t.block.get_authorization_filter
            if t.authorization_filter
              # Has PEP
              # $log.error "check_inconsistent_authorization #{t.id} has PEP"
              no_pep = false
            else
              # No PEP
              # same domain?
              if ss.req_policies.size == 0
                # No policy
                type = 0
              elsif ss.req_policies.size == 1
                # single req policy
                if ss.req_policies[0].is_authorized
                  # $log.error "check_inconsistent_authorization #{t.id} no PEP but auth state"
                  no_pep = false
                else
                  type = 1
                end
              else
                # $log.error "check_inconsistent_authorization #{t.id} no PEP many pol - TODO"
                no_pep = false
              end
            end
          else
            no_pep = false
          end
          if no_pep
            if t.authorization_filter
              $log.error "TODO: no PEP"
              type = 2
              t.nav_error = true
              ss.nav_error  = true
              w = Hash.new
              w['warning_type'] = 'Missing controller side authorization check'
              w['message'] = "View #{t.src_id} has authorization check, but enforcement at controller side #{t.dst_id} is missing."
              w['file'] = t.filename # TODO: controller
              w['line'] = nil
              w['code'] = nil
              w['location'] = nil
              w['user_input'] = nil
              w['confidence'] = 'Weak'    # Weak Medium High
              $warning.add(w)
              print_nav_error(t, ss_code_policy_level, ds_code_policy_level, "missing authorization (type #{type})") if $enable_stdout
            else
              # No PEP at dst
              t.nav_error = true
              ss.nav_error  = true
              w = Hash.new
              w['warning_type'] = 'Missing view side authorization check'
              w['message'] = "View #{t.src_id} has NO-authorization check, but enforcement at controller side #{t.dst_id}."
              w['file'] = t.filename # TODO: controller
              w['line'] = nil
              w['code'] = nil
              w['location'] = nil
              w['user_input'] = nil
              w['confidence'] = 'Weak'    # Weak Medium High
              $warning.add(w)
              print_nav_error(t, ss_code_policy_level, ds_code_policy_level, "missing authorization (type #{type})") if $enable_stdout
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

                  print_df_error(df, ss.code_policy.level, ds.code_policy.level) if $enable_stdout
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
