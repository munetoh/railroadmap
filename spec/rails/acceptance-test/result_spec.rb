# -*- coding: UTF-8 -*-
#
# rspec --color spec/rails/acceptance-test/result_spec.rb
#
# generate cucumber.json
#  $ railroadmap genuat
#  $ cucumber --format json --out cucumber.json features/railroadmap_*.feature
#  $ cp cucumber.json  HERE
#
# 1) Nav model -> test_selection
# 2) test_selection + test_plan -> testcase
# 3) run cucumber
#      cucumber --format json
#      cucumber --format json  --out cucumber.json features/railroadmap_RRMW0002.feature
#      cucumber --format json_pretty  --out cucumber.json features/railroadmap_RRMW0002.feature
#
#      http://jsonlint.com/
#
# 4) check result
#
#

require 'spec_helper'
require 'railroadmap/warning.rb'
require 'railroadmap/rails/security-check'
require 'railroadmap/rails/cucumber'

describe Abstraction::Parser::View do
  it ": load cucumber result" do

    at = Rails::Cucumber.new
    at.test_selection = {
      "TT1" => {
          id: "RRMT0001",
          name: "TT1",
          type: "sf_type",
          subtype: 'warning',
          status: "ready",
          uat_ids: ["navigation-error;scenario:-navigation-and-authorization---to-be"],
          result: "unknown"
      },
      "TT2" => {
          id: "RRMT0002",
          name: "TT2",
          type: "sf_type",
          subtype: 'warning',
          status: "ready",
          uat_ids: ["NA"],
          result: "unknown"
      },
      "TT3" => {
          id: "RRMT0003",
          name: "TT2",
          type: "sf_type",
          subtype: 'warning',
          status: "ready",
          uat_ids: ["NA"],
          result: "unknown"
      },
      "TT4" => {
          id: "RRMT0004",
          name: "TT2",
          type: "sf_type",
          subtype: 'warning',
          status: "ready",
          uat_ids: ["NA"],
          result: "unknown"
      },
      "TT5" => {
          id: "RRMT0005",
          name: "TT2",
          type: "sf_type",
          subtype: 'warning',
          status: "ready",
          uat_ids: ["NA"],
          result: "unknown"
      },
      "TT6" => {
          id: "RRMT0006",
          name: "TT2",
          type: "sf_type",
          subtype: 'warning',
          status: "ready",
          uat_ids: ["NA"],
          result: "unknown"
      },
      "TT7" => {
          id: "RRMT0007",
          name: "TT2",
          type: "sf_type",
          subtype: 'warning',
          status: "ready",
          uat_ids: ["NA"],
          result: "unknown"
      },
      "TT8" => {
          id: "RRMT0008",
          name: "TT2",
          type: "sf_type",
          subtype: 'warning',
          status: "ready",
          uat_ids: ["NA"],
          result: "unknown"
      },
    }

    # at.print_test_selection
    at.test_selection['TT1'][:result].should eq 'unknown'
    at.test_selection['TT3'][:result].should eq 'unknown'

    # load
    at.parse_cucumber_result('spec/rails/acceptance-test/cucumber.json')

    # check
    at.print_test_selection
    at.test_selection['TT1'][:result].should eq 'failed'
    at.test_selection['TT3'][:result].should eq 'unknown'
  end
end
