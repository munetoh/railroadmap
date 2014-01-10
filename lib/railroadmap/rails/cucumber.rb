# -*- coding: UTF-8 -*-
# Testcase gen for Cucumber
#
# V010
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
#
# 2013-12-15 v020
#

require 'railroadmap/rails/acceptance-test'

module Rails
  # Cucumber TDD/BDD
  class Cucumber < Rails::AcceptanceTest
    def initialize
      super
      @name = 'Cucumber'
    end

    # sample testplan
    def print_sample_testplan(filename = nil)
      json = {}

      @test_selection.each do |k, ts|
        if ts[:type] == 'csrf'
          json[k] = sample_testplan_csrf
        elsif ts[:type] == 'authentication'
          json[k] = sample_testplan_authentication
        elsif ts[:type] == 'global_authorization'
          json[k] = sample_testplan_global_authorization
        elsif ts[:type] == 'conditional_authorization'
          json[k] = sample_testplan_conditional_authorization
        else
          json[k] = { type: ts[:type], testcase_type: "skip" }
        end
      end

      out = JSON.pretty_generate(json)
      if filename.nil?
        # STDOUT
        puts "#{out}"
      else
        open(filename, "w") do |f|
          f.write(out)
        end
      end
    end

    # Remidiation for cucumber
    # TODO: msg -> JSON
    def print_remidiations
      msg = ''
      @test_selection.each do |k, t|
        if t[:status] == 'preparation'
          # listed, but no plan is assigned for this
          providedby = t[:command].providedby unless t[:command].nil?
          if t[:subtype] == 'warning'
            msg += "      #{k} has NO PLAN  #{t[:type]}, from warning\n"
          else
            msg += "      #{k} has NO PLAN  #{t[:type]}, providedby=#{providedby}\n"
          end

          # TODO: show remidiations
          type = t[:type]
          if type == 'Cross Site Scripting'
            # TODO: move to cucumber?
            msg += "        locations:\n"
            msg += "          file    : #{t[:locations][:file]}\n"
            msg += "          state   : #{t[:locations][:state]}\n"
            msg += "          variable: #{t[:locations][:variable]}\n"
            msg += "---\n"
            msg += "\"#{k}\": {\n"
            msg += "  \"type\": \"Cross Site Scripting\",\n"
            msg += "  \"subtype\": \"Type 1: Reflected XSS\",\n"
            msg += "  \"testcase_type\": \"Modification of existing testcase\",\n"
            msg += "  \"testcase\": {\n"
            msg += "    \"init_steps\": [\"LOCATION\"],\n"
            msg += "    \"target_steps\": [\"And I fill in \\u0022TARGET\\u0022 with\"],\n"
            msg += "    \"post_step\": \"And I press \\u0022Ask Everyone\\u0022\"\n"
            msg += "  }\n"
            msg += "}\n"
            msg += "---\n"
          elsif type == 'anti_xss'
            msg += "         => XSS warnings\n"
          elsif type == 'Missing view side authorization check'
            msg += "        locations:\n"
            msg += "          file    : #{t[:locations][:file]}\n"
            msg += "          state   : #{t[:locations][:state]}\n"
            msg += "          variable: #{t[:locations][:variable]}\n"
            msg += "---\n"
            msg += "\"#{k}\": {\n"
            msg += "  \"type\": \"#{type}\",\n"
            msg += "  \"testcase_type\": \"Use existing testcase\",\n"
            msg += "  \"testcases\": {\n"
            msg += "    \"SCENARIO_NAME_01\": [\n"
            msg += "      \"STEP_01\",\n"
            msg += "      \"STEP_02\"\n"
            msg += "    ],\n"
            msg += "    \"SCENARIO_NAME_02\": [\n"
            msg += "      \"STEP_01\",\n"
            msg += "      \"STEP_02\"\n"
            msg += "    ]\n"
            msg += "  }\n"
            msg += "}\n"
            msg += "---\n"
          else
            msg += "        TBD type=#{type}\n"
          end
        end
      end
      print "\e[31m"  # red
      print msg
      print "\e[0m" # reset
    end

    # --------------------------------------------------------------------------
    # Rails:CSRF
    # config/environments/test.rb
    # config.action_controller.allow_forgery_protection = true
    def sample_testplan_csrf
      tp = {}
      tp[:type] = 'csrf'
      tp[:testcase_type] = 'Modification of existing testcase'
      tp[:testcase] = {}
      tp[:testcase][:init_steps] = [
        "Given I'm logged in as someone",
        "When I visit the TARGET page"]
      tp[:testcase][:target_step]  = "And I press \u0022BUTTON_LABEL\u0022"
      tp[:testcase][:normal_step] = "Then I should see NORMAL_MSG"
      tp[:testcase][:tampered_step] = "Then I should see TAMPERED_MSG"
      tp[:comment] = 'adjust steps to fit your spec, set config.action_controller.allow_forgery_protection = true in config/environments/test.rb'
      return tp
    end

    # Generate Cucumber test cases for CSRF attack
    def generate_csrf_testcase(testplan)
      fail "nil" if testplan.nil?
      id = testplan["id"]

      tc  = "Feature: CWE-352: Cross-Site Request Forgery (CSRF)\n"
      tc += "  The web application does not, or can not, sufficiently verify\n"
      tc += "  whether a well-formed, valid, consistent request was intentionally\n"
      tc += "  provided by the user who submitted the request.\n"
      tc += "\n"

      if testplan["testcase_type"] == 'automatic'
        location = get_location(testplan["location"])
        label = testplan[:button_label] ||= 'Submit'
        success_message = testplan[:success_message] ||= 'DDD'
        fail_message = testplan[:fail_message] ||= 'You need to sign in or register before continuing.'

        # Valiables
        tcv = ''
        unless testplan['variables'].nil?  # JSON :variables => 'variables'
          count = 0
          testplan['variables'].each do |v|
            variable = get_variable(v["id"])
            value    = v["value"]
            if count == 0
              tcv += "    Given I have entered \"#{variable}\" with \"#{value}\"\n"
            else
              tcv += "    and I have entered \"#{variable}\" with \"#{value}\"\n"
            end
            count += 1
          end
        end

        tc += "  Scenario: #{id}[0]\n"
        tc += "    normal access\n"
        tc += "    Given I am on the #{location} path\n"
        tc += tcv
        tc += "    When I press \"#{label}\"\n"
        tc += "    Then I should see \"#{success_message}\"\n"
        tc += "\n"
        # TODO: spec
        # tc += "  Scenario Outline: missing hidden_field\n"
        # tc += "    When I press \"#{label}\" without authenticity_token\n"
        # tc += "    Then I should see \"You need to sign in or register before continuing.\"\n"
        # tc += "\n"
        tc += "  Scenario: #{id}[1]\n"
        tc += "    tampered hidden_field\n"
        tc += "    Given I am on the #{location} path\n"
        tc += tcv
        tc += "    When I press \"#{label}\" with tampered authenticity_token\n"
        tc += "    Then I should see \"#{fail_message}\"\n"
        tc += "\n"
      else # Modification of existing testcase
        testcase = testplan["testcase"]
        init_steps = testcase["init_steps"]
        target_step = testcase["target_step"]
        normal_step = testcase["normal_step"]
        tampered_step = testcase["tampered_step"]
        # Force log off
        tampered_step ||= "Then I should see that you need to sign in or sign up before continuing."

        tc +=  "  Scenario: #{id}[0]\n"
        tc +=  "    normal access (existing testcase)\n\n"
        init_steps.each do |s|
          tc +=  "    " + s + "\n"
        end
        tc +=  "    " + target_step + "\n"
        tc +=  "    " + normal_step + "\n\n"

        tc +=  "  Scenario: #{id}[1]\n"
        tc +=  "    tampered hidden_field (existing testcase)\n\n"
        init_steps.each do |s|
          tc +=  "    " + s + "\n"
        end
        tc +=  "    " + target_step + " with tampered authenticity_token\n"
        tc +=  "    " + tampered_step + "\n\n"
      end

      return tc
    end

    # --------------------------------------------------------------------------
    # authentication
    def sample_testplan_authentication
      tp = {}
      tp[:type] = 'authentication'
      tp[:testcase_type] = 'automatic'
      tp[:target_path] = 'YOUR_PATH, e.g., users/edit'
      tp[:success_text] = "ANY_MSG"
      tp[:error_text] = "You need to sign in or sign up before continuing."
      tp[:comment] = 'adjust the path and text messages'
      return tp
    end
    # Generate Cucumber test cases for authentication
    # http://cwe.mitre.org/data/definitions/287.html
    # testplan:
    #   target_state:
    #     OR
    #   target_path:
    #
    #   success_text:
    #   error_text:
    def generate_authentication_testcase(testplan)
      fail "nil" if testplan.nil?
      id = testplan["id"]

      tc  = "Feature: CWE-287: Improper Authentication\n"
      tc += "  When an actor claims to have a given identity, the software does\n"
      tc += "  not prove or insufficiently proves that the claim is correct.\n"
      tc += "\n"

      # TODO: devise
      if testplan["testcase_type"] == 'automatic'
        if testplan["target_path"].nil?
          if testplan["target_state"].nil?
            $log.error "generate_authentication_testcase set target_path OR target_state"
          else
            # sid = testplan["target_state"]
            # TODO: SID to path
            $log.error "TODO"
             path = "TODO"
          end
        else
          path = testplan["target_path"]
        end

        if testplan["success_text"].nil?
          $log.error "generate_authentication_testcase set success_text"
          success_text = "TODO"
        else
          success_text =  testplan["success_text"]
        end

        if testplan["error_text"].nil?
          $log.error "generate_authentication_testcase set success_text"
          error_text = "You need to sign in or sign up before continuing."
        else
          error_text =  testplan["error_text"]
        end

        tc += "  Scenario: #{id}[0]\n"
        tc += "    authenticated access\n\n"
        tc += "    Given a logged in user\n"
        tc += "    And I am on the #{path}\n"
        tc += "    # Then show me the page\n"
        tc += "    Then I should see \"#{success_text}\"\n"
        tc += "\n"
        tc += "  Scenario: #{id}[1]\n"
        tc += "    non-authenticated access\n\n"
        # tc += "    Given I am not logged in\n"
        tc += "    Given I am on the #{path}\n"
        tc += "    # Then show me the page\n"
        tc += "    Then I should see \"#{error_text}\"\n"
        tc += "\n"
      end
      return tc
    end

    # --------------------------------------------------------------------------
    def sample_testplan_global_authorization
      tp = {}
      tp[:type] = 'global_authorization'
      tp[:testcase_type] = 'automatic'
      tp[:strong_privilege_user] = 'admin'
      tp[:weak_privilege_user] = "user"
      tp[:success_text] = "SET_MSG"
      tp[:error_text] = "You are not authorized to access this page"
      tp[:comment] = 'adjust the user and text messages'
      return tp
    end

    def sample_testplan_conditional_authorization
      tp = {}
      tp[:type] = 'conditional_authorization'
      tp[:testcase_type] = 'Use existing testcase'
      tp[:testcases] = {
        "navigation and authorization - OK" => [
          "Given questions exist",
          "Given a logged in moderator",
          "When I visit the questions page",
          "When I click the first question link",
          "# Then show me the page",
          "Then I should see \\u0022Edit\\u0022"
        ],
        "navigation and authorization - NG" => [
          "Given questions exist",
          "Given a logged in user",
          "When I visit the questions page",
          "When I click the first question link",
          "# Then show me the page",
          "Then I should not see \\u0022Edit\\u0022"
        ]
      }
      tp[:comment] = 'adjust the test scenario'
      return tp
    end

    # Generate Cucumber test cases for authorization
    # http://cwe.mitre.org/data/definitions/285.html
    # to test this, we need two pages(state) with different privileges.
    # type: global_authorization
    # scenarios:
    #   strong user access weak and strong path => OK
    #   weak user access weak and strong path => NG
    # testplan:
    #   weak_privilege_path:
    #   strong_privilege_path:
    #   success_text:
    #   error_text:
    def generate_authorization_testcase(testplan)
      fail "nil" if testplan.nil?
      id = testplan["id"]

      tc  = "Feature: CWE-285: Improper Authorization\n"
      tc += "  The software does not perform or incorrectly performs an \n"
      tc += "  authorization check when an actor attempts to access a \n"
      tc += "  resource or perform an action.\n"
      tc += "\n"

      # TODO: CanCan
      if testplan["testcase_type"] == 'automatic'
        strong_privilege_user = testplan['strong_privilege_user']
        weak_privilege_user = testplan['weak_privilege_user']
        strong_privilege_path = testplan["strong_privilege_path"]
        success_text = testplan["success_text"]
        error_text   = testplan["error_text"]

        tc += "  Scenario: #{id}[0]\n"
        tc += "    authorized access\n\n"
        tc += "    Given a logged in #{strong_privilege_user}\n"
        tc += "    When I visit the #{strong_privilege_path}\n"
        tc += "    Then I should see \"#{success_text}\"\n"
        tc += "\n"
        tc += "  Scenario: #{id}[1]\n"
        tc += "    non-authorized access\n\n"
        tc += "    Given a logged in #{weak_privilege_user}\n"
        tc += "    When I visit the #{strong_privilege_path}\n"
        tc += "    Then I should see \"#{error_text}\"\n"
        tc += "\n"
      else
        $log.error "TODO:"
      end
      return tc
    end

    # This is a check of navigation error (BUG)
    # View template --auth check--> View page --trans --> Controller
    def generate_conditional_authorization_testcase(testplan)
      fail "nil" if testplan.nil?
      id = testplan["id"]

      tc  = "Feature: Navigation error\n"
      tc += "  The software does not perform or incorrectly performs an \n"
      tc += "  authorization check when generating a HTML page.\n"
      tc += "\n"

      if testplan["testcase_type"] == 'Use existing testcase'
        # TODO: be a common method
        testcases = testplan["testcases"]
        count = 0
        testcases.each do |scenario, steps|

          tc += "  Scenario: #{id}[#{count}]\n"
          tc += "    #{scenario}\n\n"
          steps.each do |line|
            tc += "    #{line}\n"
          end
          tc += "\n"
          count += 1
        end
      else
        $log.error "TODO:"
      end
      return tc
    end

    # --------------------------------------------------------------------------
    #
    # Generate Cucumber test cases for Cross-site scripting attack
    #   init_steps
    #   target_steps
    #   post_step
    def generate_xss_testcase(testplan)
      fail "nil" if testplan.nil?
      id = testplan["id"]

      tc  = "Feature: CWE-79 : Failure to Preserve Web Page Structure (Cross-site Scripting)\n"
      tc += "  The software does not neutralize or incorrectly neutralizes user-controllable input \n"
      tc += "  before it is placed in output that is used as a web page that is served to other users.\n"
      tc += "\n"

      if testplan["testcase_type"] == 'Modification of existing testcase'
        testcase     = testplan["testcase"]
        init_steps   = testcase["init_steps"]
        target_steps = testcase["target_steps"]
        post_step    = testcase["post_step"]
        variable     = 'TBD'

        tc +=  "  Scenario: #{id}[0]\n"
        tc +=  "    XSS injection #{testplan['name']}\n\n"
        init_steps.each do |s|
          tc +=  "    " + s + "\n"
        end
        tc +=  "    # Then show me the page\n"
        count = 0
        target_steps.each do |s|
          xss = "\"<b>hello_#{count}</b><script>XSS_#{count}</script>\""
          tc +=  "    " + s + " #{xss}\n"
          count += 1
        end
        tc +=  "    " + post_step + "\n"
        tc +=  "    # Then show me the page\n"
        count = 0
        target_steps.each do |s|
          xss = "\"<b>hello_#{count}</b><script>XSS_#{count}</script>\""
          if count == 0
            head = "    Then "
          else
            head = "    And  "
          end
          tc +=  head + "I should not see #{xss} in raw\n\n"
          count += 1
        end
      else
        tc += "# TODO: Modification of existing testcase only"
      end
      return tc
    end

    # --------------------------------------------------------------------------
    # Result
    # log/test.log
    # --format html --out output.html
    # cucumber --format json
    # cucumber --format json_pretty
    # "id"=>"navigation-error;scenario:-navigation-and-authorization---to-be",
    def parse_cucumber_result(filename)
      cucumber_result = nil
      open(filename, 'r') { |fp|
        cucumber_result = JSON.parse(fp.read)
      }

      test_count = 0
      passed_count = 0
      undefined_count = 0
      skipped_count = 0
      failed_count = 0

      cucumber_result.each do |f|
        elements = f['elements']
        elements.each do |e|
          name = e['name']
          steps = e['steps']
          id = e['id']
          steps.each do |s|
            result = s['result']
            status = result['status']
            id, index = get_id(e['name'])
            update_test_selection(id, status, e)
            test_count += 1
            passed_count += 1 if status == 'passed'
            undefined_count += 1 if status == 'undefined'
            skipped_count += 1 if status == 'skipped'
            failed_count += 1 if status == 'failed'
            # pp status
          end
        end
      end

      puts "    total test steps     : #{test_count}"
      if undefined_count > 0 || failed_count > 0
        print "\e[31m"  # red
        puts "      failed test        : #{failed_count}"
        puts "      undefined test     : #{undefined_count}"
        puts "      skipped test       : #{skipped_count}"
        print "\e[0m" # reset
      end
    end  # dev

    # RRMT0001[0] => RRMT0001, 0
    # TODO: move to at.rb?
    def get_id(name)
      /RRMT([0-9]+)\[([0-9]+)\]/ =~ name
      # id = 'RRMT' + $1
      id = 'RRMT' + Regexp.last_match[1]
      # index = $2
      index = Regexp.last_match[2]
      return id, index
    end

    def update_test_selection(id, status, detail)
      return nil if @test_selection.nil?
      @test_selection.each do |k, ts|
        unless ts[:id].nil?
          if ts[:id] == id
            if ts[:result] == 'failed'
              # Update Keep
              ts[:result_detail] += json2html(detail)
            else
              ts[:result] = status  # TODO: override
              ts[:result_detail] = json2html(detail)  # TODO: JSON to test or HTML
            end
          end
        end
      end
    end

    # TODO: show cucumber result at dashboard
    def json2html(json)
      msg = ''
      if json["type"] == 'scenario'
        msg += "#{json['keyword']}: #{json['name']}<br>"
        msg += "  #{json['description']}<br>"
        steps = json["steps"]
        steps.each do |step|
          # TODO; escape
          # name = step['name']
          name = ''
          msg += "  #{step['keyword']} #{name}<br>"
          result = step['result']
          if result['status'] == 'failed'
            # TODO: escape
            # error_message = result['error_message']
            # error_message.gsub!('\n', '')
            # msg += "  ERROR: #{error_message}"
            msg += "  ERROR <br>"
          end
        end
      end
      return msg
    end

  end  # class
end  # module
