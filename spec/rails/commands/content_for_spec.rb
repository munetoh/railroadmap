# -*- coding: UTF-8 -*-
# v02X
#
# Test for
#   View content_for
#   ERB  -> AST
#   Haml -> AST
#
# rspec --color spec/rails/commands/content_for_spec.rb
#
#  API ref => http://apidock.com/rails/ActionView/Helpers/CaptureHelper/content_for
#
# Typical usage, control the form content from parents view template
#   conent_fot :edit do link_to...      in index.erb
#   conent_fot:edit                     in _form.erb
#
#   index.erb  --> _form.erb --link_to--->  C_edit
#
#   parent view state hold the list of content_for in SEXP
#   _form view state check them?
#      if _form is shared by multiple state, how to handle then?
#      also V-V link is not established.
#
# For now (v0.2.1)
#  If the content includes a command like 'link_to', the transition
#  generated at declaration state, not used state.
#  Thus, the trans has wrong source state.
#  This must be fixed manually.
#  $app_id2id supports to fix wrong distination id.
#  Introduce new conf, $app_fix_trans?
#
# TODO: Quick update plan v0.2.2?
#  Add Error message to indicate the existance of content_for.
#  Then, user must fix the src_id of trans within content_for manually.
#
# TODO: v0.3?
#  * Parse the state by 2 phases
#     1. check the file, and create all MVC states (stations),
#     2. check the all code and create the transitions and dataflow (rails)

require 'spec_helper'

# sample ERB codes
erb_code1 = <<"EOS"
<% content_for :not_authorized do %>
  alert('You are not authorized to do that!')
<% end %>
EOS

erb_code2 = <<"EOS"
<%= content_for :not_authorized if current_user.nil? %>
EOS
# >

erb_code3 = <<"EOS"
<% content_for :navigation do %>
  <li><%= link_to 'Home', :action => 'index' %></li>
<% end %>
EOS
# >

erb_code4 = <<"EOS"
<%= content_for :navigation %>
EOS
# >

describe Abstraction::Parser::View do
  it ": init railroadmap" do
    init_railroadmap
    $apv = Abstraction::Parser::View.new
    $apv.add_json_command_list('./lib/railroadmap/command_library/rails.json')
  end

  it ": Parse content_for 1 (ERB)" do
    # ERB -> Ruby -> AST
    ruby_code1 = Erb::Stripper.new.to_ruby(erb_code1)
    sexp1 = Ripper.sexp(ruby_code1)
    # pp sexp1

    $apv.parse_sexp(0, sexp1)
    # pp $abst_commands

    # ruby_code2 = Erb::Stripper.new.to_ruby(erb_code2)
    # sexp2 = Ripper.sexp(ruby_code2)
    # pp sexp2

  end

  it ": Parse content_for 3, w/ link_to (ERB)" do
    # add dummy state
    $state = $apv.add_state('view', 'hoge#index', nil)

    # ERB -> Ruby -> AST
    ruby_code3 = Erb::Stripper.new.to_ruby(erb_code3)
    sexp3 = Ripper.sexp(ruby_code3)
    # pp sexp3

    $apv.parse_sexp(0, sexp3)
    # pp $abst_commands
    # pp $abst_transitions

    # ruby_code2 = Erb::Stripper.new.to_ruby(erb_code2)
    # sexp2 = Ripper.sexp(ruby_code2)
    # pp sexp2

  end
end
