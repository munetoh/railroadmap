# # -*- coding: UTF-8 -*-
#
# CanCan
# https://github.com/ryanb/cancan
#
# rspec --color spec/rails/commands/cancan2_spec.rb
#
#
#  View can can?

require 'spec_helper'
require 'railroadmap/rails/cancan'
require 'railroadmap/rails/security-check'
require 'railroadmap/rails/requirement'

#  Navigation error? V_user#show[lv:0] => C_devise:registration#edit[lv:15]
haml_code_001 = <<"EOS"
%hr
  - if can? :update, resource
    = link_to "Change My Settings", edit_registration_path(resource), :class => "btn success"
EOS

haml_code_002 = <<"EOS"
%hr
  = link_to "Change My Settings", edit_registration_path(resource), :class => "btn success"
EOS

describe Abstraction::Parser::View do

  it ": init railroadmap" do
    init_railroadmap
    $apv = Abstraction::Parser::View.new
    $apc = Abstraction::Parser::Controller.new
    $abs = Abstraction::MVC.new
    $abs.add_json_command_list('./lib/railroadmap/command_library/rails.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/cancan.json')

    $authorization_module = Rails::CanCan.new
    $req = Rails::Requirement.new
  end

  it ": navigation with can?" do
    $abst_states = {}
    sc1    = $apv.add_state('controller', 'devise:registration#edit', nil)
    $state = $apv.add_state('view', 'user#show', nil)
    $abst_transitions_count = 0
    $abst_transitions = {}

    # HAML -> Ruby -> AST
    ruby_code = $apv.conv_haml2ruby(haml_code_001)
    sexp = Ripper.sexp(ruby_code)

    $apv.parse_sexp(0, sexp)
    # pp $abst_commands
    # pp $abst_transitions
    # list_commands

    # One link?
    $abst_transitions_count.should eq 1

    # pp $authorization_filter_list
    t = $abst_transitions['T_V_user#show#0']

    guard2abst = Hash.new
    # guard2abst['can?:updateresource == true'] = 'can?(user, edit)'
    guard2abst['sign_in == true'] = 'sign_in'
    guard2abst_byblk = Hash.new # TODO
    t.block.complete_condition(nil, nil, guard2abst, guard2abst_byblk)

    # lib/railroadmap/security-assurance-model.rb:
    t.authorization_filter = t.block.get_authorization_filter
    # pp t.block.abst_condition_success
    # t.authorization_filter.should eq true

    # FIX Model
    t.dst_id = 'C_devise:registration#edit'
    ds = $abst_states[t.dst_id]
    ds.code_policy.is_authorized = true

    # pp $abst_transitions
    t.authorization_filter.name.should eq 'can?'

    # TODO: sec test
    sc = Rails::SecurityCheck.new # run static analysis
    # pp $warning
    # list_warnings
    # list_transitions
    $warning.count.should eq 1
  end

  it ": navigation without can?" do
    $warning = Warning.new
    $abst_states = {}
    sc1    = $apv.add_state('controller', 'devise:registration#edit', nil)
    $state = $apv.add_state('view', 'user#show', nil)
    $abst_transitions_count = 0
    $abst_transitions = {}

    # HAML -> Ruby -> AST
    ruby_code = $apv.conv_haml2ruby(haml_code_002)
    sexp = Ripper.sexp(ruby_code)

    $apv.parse_sexp(0, sexp)
    # pp $abst_commands
    # pp $abst_transitions
    # list_commands

    # One link?
    $abst_transitions_count.should eq 1

    # pp $authorization_filter_list
    t = $abst_transitions['T_V_user#show#0']

    guard2abst = Hash.new
    # guard2abst['can?:updateresource == true'] = 'can?(user, edit)'
    guard2abst['sign_in == true'] = 'sign_in'
    guard2abst_byblk = Hash.new # TODO
    t.block.complete_condition(nil, nil, guard2abst, guard2abst_byblk)

    # lib/railroadmap/security-assurance-model.rb:
    t.authorization_filter = t.block.get_authorization_filter
    # pp t.block.abst_condition_success
    # t.authorization_filter.should eq true

    # FIX Model
    t.dst_id = 'C_devise:registration#edit'
    ds = $abst_states[t.dst_id]
    ds.code_policy.is_authorized = true

    # pp $abst_transitions
    t.authorization_filter.should eq nil

    # TODO: sec test
    sc = Rails::SecurityCheck.new # run static analysis
    # pp $warning
    # list_warnings
    # list_states
    # list_transitions
    $warning.count.should eq 2
  end
end
