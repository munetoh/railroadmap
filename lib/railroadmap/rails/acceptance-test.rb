# -*- coding: UTF-8 -*-
# acceptance test
#
# 1) Selection phase
#    select test target location for each security function
#
# 2) Testcase generation phase
#    generate testcases for each location
#    test pattern is defiend by command_library
#
#  user maintains
#    railroadmap/testplan.rb
#
# Test location
#   SF       raw
#   ELSE     csrf
#     location_type   post
#     location        any_input
#
# Test pattern
#   injection
#     check_firstorder_ouput
#     check_secondorder_ouput
#
#   authentication
#     success_message
#     fail_massage
#
#   authorization
#
#  Indexing policy
#    test_selection    RRMT0001
#    test_plan         RRMT0001
#    cucumber:senario  RRMT0001[0]
#
#
# Test: RSpec
#   rspec --color spec/rails/acceptance-test/csrf_spec.rb
#   rspec --color spec/rails/acceptance-test/xss_spec.rb
#   rspec --color spec/rails/acceptance-test/result_spec.rb
#
module Rails
  # Acceptance Test
  class AcceptanceTest
    def initialize
      @name = 'common'
      @test_selection = nil   # ID: {SF: LOCATIONS: }
      @test_plan = nil # JSON
    end
    attr_accessor :test_selection

    # Select a security test target
    #  1) By security function
    #  2) By warning
    def init_test_selection
      @test_selection = {}
      count = 0
      # Command based selection
      if $abst_commands.size == 0
        $log.error "no commands"
      else
        $abst_commands.each do |k, c|

          status = 'preparation'  # preparation->ready prepared
          if c.count > 0 && c.is_sf
            # SF used in the app
            if c.testcase_type == 'none'
              # skip
            else
              # add to the selection
              id = format("RRMT%04d", count)
              @test_selection[k] = {
                id: id,
                name: k,
                type: c.sf_type,
                subtype: 'function',
                status: status,
                command: c,
                locations: c.location_list,
                result: "unknown" }
              count += 1
            end
          end
        end
      end

      # Warning based solurion
      $warning.warnings.each do |k, w|
        status = 'preparation'  # preparation->ready prepared
        type = w['warning_type']

        add_ts = false
        if type == 'Cross Site Scripting'
          add_ts = true
          locations = { file: w['file'], state: w['hit_state'], variable: w['hit_variable'] }
        elsif type == 'Missing view side authentication check'
          # Navigation error
          add_ts = true
          locations = { file: w['file'], state: w['hit_state'], variable: w['hit_variable'] }
        elsif type == 'Missing view side authorization check'
          # Navigation error
          add_ts = true
          locations = { file: w['file'], state: w['hit_state'], variable: w['hit_variable'] }
        else
          $log.error "TODO: #{type}"
        end

        if add_ts
          id = format("RRMT%04d", count)
          locations = { file: w['file'], state: w['hit_state'], variable: w['hit_variable'] }
          @test_selection[k] = {
            id: id,
            name: k,
            type: type,
            subtype: 'warning',
            status: status,
            locations: locations,
            result: "unknown" }
          count += 1
        end
      end
      return @test_selection
    end

    def load_testplan(filename)
      # check
      unless File.exist?(filename)
        print "\e[31m"  # red
        puts "test plan #{filename} is missing."
        puts "create initial file? [Y/n/p(print only)]"
        ans = STDIN.gets
        ans = ans.chomp.downcase

        if ans == 'y'
          # Make sample
          print_sample_testplan(filename)
          print "\e[0m" # reset
        elsif ans == 'p'
          # Make sample
          print_sample_testplan
          print "\e[0m" # reset
          exit
        else
          puts "please prepare #{filename}"
          print "\e[0m" # reset
          exit
        end
      end

      open(filename) do |f|
        @test_plan = JSON.load(f)
      end

      set_testplan(@test_plan)
    end

    def print_sample_testplan(filename = nil)
      $log.error "#{@name} does not support a sample testplan"
      exit
    end

    # test_selection <-> test_plan
    def set_testplan(testplan)
      has_error = false
      msg = ''
      unless @test_selection.nil?
        # TODO: check any inconsistency
        testplan.each do |k, p|
          if @test_selection[k].nil?
            testplan[k][:status] = 'error'
            testplan[k][:error]  = 'missing security function'
            msg += "      plan #{k} does not found in the test selection list\n"
            has_error = true
          else
            # hit
            if p['testcase_type'] == 'skip'
              @test_selection[k][:status] = 'skip'
              @test_selection[k][:result] = 'skip'
              @test_selection[k][:testplan] = p
            else
              # check type
              type = testplan[k]["type"]
              if type == @test_selection[k][:type]
                # $log.error "set_testplan() HIT #{k}"
                p['name'] = k
                p['id'] = @test_selection[k][:id]
                @test_selection[k][:status] = 'ready' # ?
                # check
                if !p[:location].nil? && $abst_states[p[:location]].nil?
                  $log.error "set_testplan() MISS target state"
                  puts "location=#{p[:location]} is missing"
                  testplan[k][:status] = 'error'
                  testplan[k][:error]  = 'missing location'
                  @test_selection[k][:status] = 'error'
                  @test_selection[k][:error] = 'missing location'
                end
                @test_selection[k][:testplan] = p
              else
                $log.error "set_testplan(): BAD testplan type:#{type} != test_selection type:#{@test_selection[k][:type]}"
                pp testplan[k]
              end
            end
          end
        end
      end

      if has_error
        print "\e[31m"  # red
        print msg
        print "\e[0m" # reset
      end
      return @test_selection
    end

    # test_selection <-> testplan
    def check_test_selection
      count_all = 0
      count_noplan = 0
      @test_selection.each do |k, ts|
        count_all += 1
        if ts[:status] == 'ready'
          # OK
        elsif ts[:status] == 'skip'
          # Skip
        else
          count_noplan += 1
        end
      end

      if count_noplan == 0
        puts "    testcase  : #{count_all}"
        return true
      else
        count_plan = count_all - count_noplan
        print "\e[31m"  # red
        puts "    testcase  : #{count_plan} / (total selection: #{count_all})"
        print "\e[0m" # reset
        return false
      end
    end

    def generate_steps(output_path)
      filename =  output_path + '/' + 'railroadmap_steps.rb'
      if File.exist?(filename)
        # Exist, TODO: update?
        puts "   steps : #{filename}"

        # Update or not
        puts "        steps #{filename} exist."
        puts "        Update? [y/N]"
        ans = STDIN.gets
        ans = ans.chomp.downcase

        if ans == 'y'
          # make backup
          backup_filename = filename + '_' + File.stat(filename).mtime.strftime("%Y%m%d%H%M%S")
          File.rename(filename, backup_filename)
          # copy
          stepfile =  File.join(File.dirname(__FILE__), '../cucumber_library') + '/railroadmap_steps.rb'
          FileUtils.cp(stepfile, filename)
          puts "        backup #{filename} -> #{backup_filename}"
        end
      else
        # copy
        puts "   create #{filename}"
        stepfile =  File.join(File.dirname(__FILE__), '../cucumber_library') + '/railroadmap_steps.rb'
        FileUtils.cp(stepfile, filename)
      end
    end

    # output_type
    #   file   : single file
    #   dir    : multiple files / function
    #   stdout : console
    def generate_testcase(output_type = 'stdout', file = '')
      count = 0
      tc_set = []  # type, name. testcase
      @test_selection.each do |k, t|
        if t[:status] == 'ready'
          # Gen test
          tc  = ''
          if !t[:command].nil? && !t[:command].testcase_name.nil?
            name = t[:command].testcase_name
          elsif t[:subtype] == 'function'
            name = t[:type] # name=function
          else # warning
            name = t[:name] # name = warning ID
          end

          type = t[:type]
          if type == 'csrf'
            tc = generate_csrf_testcase(t[:testplan])
            tc_set << [type, name, tc]
          elsif type == 'Cross Site Scripting' || type == "anti_xss"
            tc = generate_xss_testcase(t[:testplan])
            tc_set << [type, name, tc]
          elsif type == 'authentication'
            tc = generate_authentication_testcase(t[:testplan])
            tc_set << [type, name, tc]
          elsif type == 'global_authorization'
            tc = generate_authorization_testcase(t[:testplan])
            tc_set << [type, name, tc]
          elsif type == 'conditional_authorization'
            tc = generate_conditional_authorization_testcase(t[:testplan])
            tc_set << [type, name, tc]
          elsif type == 'Missing view side authorization check'
            tc = generate_conditional_authorization_testcase(t[:testplan])
            tc_set << [type, name, tc]
          else
            $log.error "generate_testcase(): unknown type=#{t[:type]}"
            tc += ''
          end
          t[:testcase] = file + '/railroadmap_' + name + '.feature'
        end
      end

      if output_type == 'stdout'
        count = 0
        tc_set.each do |tc|
          puts "Testcase #{count}"
          print tc[2]
          count += 1
        end
      elsif output_type == 'dir'
        count = 0
        tc_set.each do |tc|
          filename = file + '/railroadmap_' + tc[1] + '.feature'
          puts "      Testcase #{count} #{filename}"
          # Update or not
          if File.exist?(filename)
            puts "        test plan #{filename} exist."
            puts "        Update? [y/N]"
            ans = STDIN.gets
            ans = ans.chomp.downcase

            if ans == 'y'
              # make backup
              backup_filename = filename + '_' + File.stat(filename).mtime.strftime("%Y%m%d%H%M%S")
              File.rename(filename, backup_filename)
              # new
              File.open(filename, 'w') { |f| f.write tc[2] }
              puts "        backup #{filename} -> #{backup_filename}"
            end
          else
            # new TC
            File.open(filename, 'w') { |f| f.write tc[2] }
          end

          count += 1
        end
      else
        $log.error "unknown #{output_type}"
      end
    end

    # Test_selection => fail => warning
    #  warning[test_type]
    #  warning[test_result]
    def update_warning_flag
      puts "    update warning flags"
      fail_count = 0
      @test_selection.each do |k, ts|
        if ts[:subtype] == 'warning'
          id = ts[:name]
          # lookup
          w = $warning.warnings[id]
          if w.nil?
            $log.error "BUG"
          else
            w['test_type'] = 'UAT:cucumber' # TODO: set
            w['test_result'] = ts[:result]
            w['comment'] = ''
            if ts[:result] == 'failed'
              w['comment'] = 'True-Positive'
              fail_count += 1
            elsif ts[:result] == 'skip'
              plan = ts[:testplan]
              w['comment'] = plan['argument'] unless plan.nil?
            else
              w['test_result'] = ts[:result]
            end
          end
        end
      end

      if fail_count > 0
        print "\e[31m"  # red
        puts "      true-positive test : #{fail_count}"
        print "\e[0m" # reset
      end
    end

    # State ID -> path
    def get_location(id)
      $path2id.each do |k, v|
        return k if v == id
      end
      return id
    end

    def get_variable(id)
      # TODO: id?
      return id
    end

    def print_test_selection
      if @test_selection.nil?
        puts "no test selection"
      else
        puts "    Acceptance test"
        @test_selection.each do |k, v|
          puts "      #{v[:id]}: #{k}, #{v[:result]}"
        end
      end
    end

  end  # class
end  # module
