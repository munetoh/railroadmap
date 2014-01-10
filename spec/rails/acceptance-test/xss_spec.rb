# -*- coding: UTF-8 -*-
#
# Acceptance test
#   test case generation for XSS
#
#   rspec --color spec/rails/acceptance-test/xss_spec.rb
#
#
# 1. setup sample MVC model
#
# 2. testcase selection
#
#    Raw?
#    h?  => default => select any test case
#
# 3. testcase generation
#
# 4. cucumber?
#

require 'spec_helper'
require 'railroadmap/warning.rb'
require 'railroadmap/rails/security-check'
require 'railroadmap/rails/xss'
require 'railroadmap/rails/cucumber'
require 'railroadmap/warning'

# http://apidock.com/rails/ActionView/Helpers/RawOutputHelper/raw
erb_code1 = <<"EOS"
<%=raw @user.name %>
<%=h @user.name %>
EOS
# >

describe Abstraction::Parser::View do

  it ": init railroadmap and MVC model" do
    puts "XSS init start"
    create_dummy_mvc_for_injection_test
    $path2id = {}
    $path2id['edit_task'] = 'C_task#edit'

    $warning.count.should eq 0
    puts "XSS init ...done"
  end

  it ": testcase selection for RAW" do
    # list_commands
    list_states
    list_dataflows

    # pp $dataflows

    # XSS static analysis
    $xss  = Rails::XSS.new
    $xss.trace_raw

    $warning.count.should eq 1

    at = Rails::Cucumber.new
    tc = at.init_test_selection

    # at.print_test_selection
    tc.size.should eq 3  # h, raw, and warning

    # select one trans, railroadmap/testplan.rb
    # JSON STYLE
    # NGtestplan = JSON.load(json_code_001)
    testplan_ng = {
      "raw" => {
        "type" => "anti_xss",
        "testcase_type" => "Modification of existing testcase",
        "testcase" => {
          "init_steps" => [
            "Given I'm logged in as someone who can post to the blog",
            "When I visit the blog admin page",
            # "And I fill out the new blog form"
            "And I fill in \"title\" with \"Test\""
          ],
          "target_step"  => "And I press \u0022Create Blog post\u0022",
          "success_step" => "Then I should see that my post has been created"
        }
      }
    }
    testplan = {
      "raw" => {
        "type" => "anti_xss",
        "subtype" => "Type 1: Reflected XSS",
        "testcase_type" => "Modification of existing testcase",
        "testcase" => {
          "init_steps" => [
            "Given I am a user that has created a question",
            "When I visit the new question page",
            # "And I fill out the new blog form"
            "And I fill in \"title\" with \"Test\""],
          "target_steps" => [
            "And I fill in \u0022Title\u0022 with",
            "And I fill in \u0022Description\u0022 with"],
          "post_step" => "And I press \u0022Ask Everyone\u0022"
        }
      }
    }
    # pp testplan

    tc = at.set_testplan(testplan)
    # pp tc
    at.print_test_selection
    tc.size.should eq 3
    # list_variables

    # Testcase generation
    # SA   => True-Negative
    # UAT  => Pass (True-Negative)
    at.generate_testcase('stdout')

  end

  it ": testcase generation " do
  end
end
