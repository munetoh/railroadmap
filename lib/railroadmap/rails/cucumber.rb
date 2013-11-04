# -*- coding: UTF-8 -*-
# Testcase gen for Cucumber
#
#
# cucumber --tags @railroadmap
#
# cucumber --require features features/railroadmap/login.feature
#
# http://lmarburger.github.io/2009/09/cucumber-features-in-subdirectories.html
# http://d.hatena.ne.jp/tkrd/20100510/1273502905
#
# config/cucumber.yml
# std_opts = "--format #{ENV['CUCUMBER_FORMAT'] || 'progress'} --strict --tags ~@wip --require features"
#
# cucumber  --tags @railroadmap_wip
#
# cucumber  --tags @railroadmap_wip --format json --out cucumber.json <= OK
#
# cucumber  --tags @railroadmap_wip --format json_pretty --out cucumber.json  <= NG???

module Rails
  # Cucumber TDD/BDD
  class Cucumber
    def initialize(dir)
      @dir = File.realpath(dir)
      puts " #{@dir}"

      @rrm_dir = @dir  # + "/railroadmap"
      FileUtils.mkdir_p(@rrm_dir) unless FileTest.exist?(@rrm_dir)
    end

    # Generate Cucumber test cases for Cross-site scripting attack
    def gen_xss_testcases(xss_test_paths)
      filename = @rrm_dir + "/xss_test.feature"
      count = 0

      if xss_test_paths.size > 0
        open(filename, "w") do |f|
          f.write "@railroadmap_wip\n"
          f.write "Feature: XSS tests generated by RailroadMap\n"
          f.write "\n"

          # Scenario for each dataflow
          xss_test_paths.each do |k, tpath|
            if tpath[0]
              # Check manualfix
              replace_given = false
              replace_given_msg = ''
              replace_given_steps = []
              unless $xss_test_path_fix.nil?
                fixes = $xss_test_path_fix[k]
                unless fixes.nil?
                  fixes.each do |f2|
                    if f2[0] == 'replace_given'
                      replace_given       = true
                      replace_given_msg   = f2[1]
                      replace_given_steps = f2[2]
                    end
                  end
                end
              end

              # $log.error "XSS #{k} => #{filename}"
              val_in_key  = tpath[2]
              val_out_key = tpath[3]
              paths       = tpath[4]
              wkey        = tpath[5]

              # Start state path
              start_state = $abst_states[paths[0][0]]
              path_in =  start_state.path

              # Input valiable
              # TODO: label or auto-label
              val_in = $abst_variables[val_in_key]
              if val_in.nil?
                form_in = 'Unknown'
              else
                form_in = val_in.attribute.capitalize  # Auto-label
              end

              tag = (("a".."z").to_a + ("A".."Z").to_a + (0..9).to_a).shuffle[0..12].join

              # Submit button, auto or label
              button = "Create " + start_state.model.capitalize # Auto

              # Cucumber Scenario OUT
              f.write "  # Warning          : #{tpath[5]}\n"  # TODO: replace to TEST ID
              f.write "  # XSS target       : #{tpath[3]}\n"  # TODO: replace to TEST ID
              f.write "  # trace tag        : #{tag}\n"
              scenario = "  Scenario: #{tpath[5]} - #{k}\n"
              # Go input page
              # TODO: User/Role
              scenario += "    Given I am logged in\n"

              if replace_given
                f.write "  # Start state      : #{start_state.id} => replaced\n"
                f.write "  #  replace         : #{replace_given_msg}\n"
                replace_given_steps.each do |s|
                  scenario += "    #{s}\n"
                end
              else
                f.write "  # Start state      : #{start_state.id}\n"
                scenario += "    Given I am on the #{path_in} page\n"
              end

              # input
              f.write "  # Input            : #{val_in_key}\n"
              scenario += "    When I fill in xss_injection_msg with \"#{tag}\" for \"#{form_in}\"\n"
              scenario += "    When I press \"#{button}\"\n"

              # trans
              # TODO: ?
              # 1st order) V+ -> C+ -> V -> no trans
              # 2nd order) V+ -> C+ -> V+ -> C+ -> V -> with trans
              step = 0
              type = 'view'
              last_key = paths[0][0]
              scenario2 = ''
              paths.each do |st|
                p st
                state = $abst_states[st[0]]

                if state.type != type
                  type = state.type
                  step += 1
                end
                if st[1].nil?
                  f.write "  # Output           : #{st[0]}\n"
                else
                  trans = $abst_transitions[st[1]]
                  if trans.type == 'link_to'
                    f.write "  # trans            : #{trans.id} #{trans.type} #{trans.title}\n"
                    scenario2 += "    When I follow \"#{trans.title}\"\n"
                  else
                    f.write "  # trans            : #{trans.id} #{trans.type}\n"
                  end
                end
                last_key = st[0]
              end
              $log.error "Path step #{step}"
              if step == 2
                # 1st order
                f.write "  # Order            : 1st\n"
              else
                # 2nd order => Jump or Trace
                f.write "  # Order            : 2nd\n"
                scenario += scenario2
              end

              # output
              scenario += "    Then I should see \"#{tag}\" in raw\n"  # TAG
              scenario += "    And I should see xss_escaped_msg in raw\n\n"
              f.write scenario
              count += 1
            end
          end # each
        end  # file
      end  # if
    end  # def
  end  # class
end  # module