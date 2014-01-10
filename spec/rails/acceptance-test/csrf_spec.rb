# -*- coding: UTF-8 -*-
#
# Acceptance test
#   test case generation for CSRF
#
#   rspec --color spec/rails/acceptance-test/csrf_spec.rb
#
#
# 1. setup sample MVC model
#
#      CSRF test => check hidden variables
#      C--hidden-->V--hidden, submit --> C --error--> C
#
# 2. testcase selection
#
# 3. testcase generation
#
# 4. cucumber?
#

require 'spec_helper'
require 'railroadmap/warning.rb'
require 'railroadmap/rails/security-check'
require 'railroadmap/rails/cucumber'
require 'railroadmap/rails/requirement'

ruby_code_001 = <<"EOS"
class ApplicationController < ActionController::Base
  protect_from_forgery
end
EOS

ruby_code_002 = <<"EOS"
class ApplicationController < ActionController::Base
end
EOS

json_code_001 = <<"EOS"
{
  "protect_from_forgery": {
    "testcase_type": "Modification of existing testcase",
    //"testcase": {
    //  "init_steps": [
    //    "Given I'm logged in as someone who can post to the blog",
    //    "When I visit the blog admin page",
    //    "And I fill out the new blog form"
    //  ],
    //  "target_step": "And I press \u0022Create Blog post\u0022",
    //  "success_step": "Then I should see that my post has been created"
    //}
  }
}
EOS

describe Abstraction::Parser::View do

  it ": init railroadmap and MVC model" do
    create_dummy_mvc_for_injection_test
    $path2id = {}
    $path2id['edit_task'] = 'C_task#edit'
    $req = Rails::Requirement.new
  end

  #
  it ": setup sample MVC application, CSRF Configured " do
    # ApplicationController
    sexp = Ripper.sexp(ruby_code_001)
    $astc.parse_sexp(0, sexp)

    # list_transisions
    # list_commands
    # pp $abst_commands
    $protect_from_forgery.should eq true

    sc = Rails::SecurityCheck.new
    $warning.count.should eq 0

    # Test selection
    # list up submit trans
    at = Rails::Cucumber.new
    tc = at.init_test_selection
    # pp tc
    # list_commands
    tc.size.should eq 3

    # select one trans, railroadmap/testplan.rb
    # JSON STYLE
    testplan = {
      "protect_from_forgery" => {
        "type" => "csrf",
        "testcase_type" => "automatic",
        "location" => 'C_task#edit',
        "variables" => [
          { "id" => 'S_task#version',
            "value" => '0.0.1' },
          { "id" => 'S_task#author',
            "value" => 'alice' }
        ]
      }
    }
    tc = at.set_testplan(testplan)
    # pp tc
    # list_variables
    tc.size.should eq 3

    # Testcase generation
    # SA   => True-Negative
    # UAT  => Pass (True-Negative)
    at.generate_testcase('stdout')
  end

  #
  it ": setup sample MVC application, CSRF Configured, JSON testplan " do
    # ApplicationController
    sexp = Ripper.sexp(ruby_code_001)
    $astc.parse_sexp(0, sexp)

    # list_transisions
    # pp $abst_commands
    $protect_from_forgery.should eq true

    sc = Rails::SecurityCheck.new
    $warning.count.should eq 0

    # Test selection
    # list up submit trans
    at = Rails::Cucumber.new
    tc = at.init_test_selection
    # pp tc
    # list_commands
    tc.size.should eq 3

    # select one trans, railroadmap/testplan.rb
    # JSON STYLE
    # NGtestplan = JSON.load(json_code_001)
    testplan = {
      "protect_from_forgery" => {
        "type" => "csrf",
        "testcase_type" => "Modification of existing testcase",
        "testcase" => {
          "init_steps" => [
            "Given I'm logged in as someone who can post to the blog",
            "When I visit the blog admin page",
            "And I fill out the new blog form"
          ],
          "target_step" => "And I press \u0022Create Blog post\u0022",
          "normal_step" => "Then I should see that my post has been created",
          "tampered_step" => "Then I should see that XXX"
        }
      }
    }
    pp testplan

    tc = at.set_testplan(testplan)
    # pp tc
    tc.size.should eq 3
    # list_variables

    # Testcase generation
    # SA   => True-Negative
    # UAT  => Pass (True-Negative)
    at.generate_testcase('stdout')
  end

  #
  it ": setup sample MVC application, CSRF Missing" do
    init_railroadmap
    sexp = Ripper.sexp(ruby_code_002)
    $ast.parse_sexp(0, sexp)

    # pp $abst_commands
    $protect_from_forgery.should eq false

    # Static analysis must report this as warning
    sc = Rails::SecurityCheck.new
    $warning.count.should eq 1

    # Test selection

    # Testcase generation
    # SA   => True-Positive
    # UAT  => Error (True-Positive)
    # list_transisions
    # list_commands
  end
end
