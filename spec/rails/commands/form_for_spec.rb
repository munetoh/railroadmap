# -*- coding: UTF-8 -*-
# v02X
#
# Test for
#   View form_for, semantic_menu
#   Ruby -> AST
#   ERB  -> AST
#   Haml -> AST
#
# rspec --color spec/rails/commands/form_for_spec.rb

require 'spec_helper'

# sample ERB and HAML codes

erb_code1 = <<"EOS"
<%= form_for @offer do |f| %>
  <%= f.label :version, 'Version' %>:
  <%= f.text_field :version %><br />
  <%= f.label :author, 'Author' %>:
  <%= f.text_field :author %><br />
  <%= f.submit %>
<% end %>
EOS

haml_code1 = <<"EOS"
= form_for @offer do |f|
  = f.label :version, 'Version'
  = f.text_field :version
  = f.label :author, 'Author'
  = f.text_field :author
  = f.submit
EOS

erb_code2 = <<"EOS"
<%= simple_form_for @user do |f| %>
  <%= f.input :username %>
  <%= f.input :password %>
  <%= f.button :submit %>
<% end %>
EOS

haml_code2 = <<"EOS"
=simple_form_for @user do |f|
  .inputs
    =f.input :username
    =f.input :password
  .actions
    =f.button :submit
EOS

haml_code3 = <<"EOS"
=simple_form_for(@message, :url => mailer_path, :test => test_path) do |f|
        =f.error_notification
        .inputs
                =f.input :subject, :hint => "Write the subject here!"
                =f.input :body, :as => :text
                -@emails.each do |email|
                        =f.input "email", :as => :text, :as => :hidden, :input_html => { :value => ""}
        .actions
                =f.button :submit , 'Send Email', :class => "primary btn"
EOS

erb_code4 = <<"EOS"
<%= semantic_menu do |root|
  root.add "overview", root_path
  root.add "comments", comments_path
end %>
EOS

# >

describe Abstraction::Parser::View do

  it ": init railroadmap" do
    init_railroadmap
    $apv = Abstraction::Parser::View.new
    $abs = Abstraction::MVC.new
    $abs.add_json_command_list('./lib/railroadmap/command_library/rails.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/simple_form.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/semantic_menu.json')
  end

  # ===============================================================================
  # form_for
  # http://apidock.com/rails/ActionView/Helpers/FormHelper/form_for
  it ": Parse form_for (ERB)" do
    #  dummy state
    $abst_states = {}
    sc1    = $apv.add_state('controller', 'offer#create', nil)
    $state = $apv.add_state('view', 'offer#new', nil)

    $abst_transitions_count = 0
    $abst_transitions = {}
    $form_target = nil

    # ERB -> Ruby -> AST
    ruby_code = Erb::Stripper.new.to_ruby(erb_code1)
    sexp = Ripper.sexp(ruby_code)
    # pp sexp

    $apv.parse_sexp(0, sexp)
    # pp $abst_commands
    # pp $abst_transitions

    # Submit/ New, Edit ?
    $abst_transitions_count.should eq 1

    t1 = $abst_transitions['T_V_offer#new#0']
    t1.src_id.should eq 'V_offer#new'
    t1.dst_id.should eq 'C_offer#create'

    # t2 = $abst_transitions['T_V_hoge#hoge#1']
    # t2.src_id.should == 'V_hoge#hoge'
    # t2.dst_id.should == 'C_hoge#update'
  end

  #-------------------------------------------------------------------------------
  it ": Parse form_for (HAML)" do
    #  dummy state
    $abst_states = {}
    sc1    = $apv.add_state('controller', 'offer#create', nil)
    $state = $apv.add_state('view', 'offer#new', nil)
    $abst_transitions_count = 0
    $abst_transitions = {}

    # HAML -> Ruby -> AST
    ruby_code = $apv.conv_haml2ruby(haml_code1)
    sexp = Ripper.sexp(ruby_code)

    $apv.parse_sexp(0, sexp)
    # pp $abst_commands
    # pp $abst_transitions

    # Submit/ New, Edit ?
    $abst_transitions_count.should eq 1
  end
  # ===============================================================================
  # simple_form_for
  # https://github.com/plataformatec/simple_form
  it ": Parse simple_form_for (ERB)" do
    # dummy state
    $abst_states = {}
    sc1    = $apv.add_state('controller', 'user#update', nil)
    $state = $apv.add_state('view', 'user#edit', nil)
    $abst_transitions_count = 0
    $abst_transitions = {}
    $form_target = 'hoge'

    # ERB -> Ruby -> AST
    ruby_code = Erb::Stripper.new.to_ruby(erb_code2)
    sexp = Ripper.sexp(ruby_code)
    # pp sexp

    $apv.parse_sexp(0, sexp)
    # pp $abst_commands
    # pp $abst_transitions

    # Submit/ New, Edit ?
    $abst_transitions_count.should eq 1
    # DST
    t = $abst_transitions['T_V_user#edit#0']
    # pp t
    t.src_id.should == 'V_user#edit'
    # t.dst_id.should == 'C_user#update'
  end

  #-------------------------------------------------------------------------------
  it ": Parse simple_form_for (HAML)" do
    #  dummy state
    $abst_states = {}
    sc1    = $apv.add_state('controller', 'user#create', nil)
    $state = $apv.add_state('view', 'user#new', nil)
    # apv.add_command_list($rails_command_list)
    $abst_transitions_count = 0
    $abst_transitions = {}

    # HAML -> Ruby -> AST
    ruby_code = $apv.conv_haml2ruby(haml_code2)
    sexp = Ripper.sexp(ruby_code)
    # puts haml_code
    # puts ruby_code
    # pp sexp

    $apv.parse_sexp(0, sexp)
    # pp $abst_commands
    # pp $abst_transitions

    # Submit/ New, Edit ?
    $abst_transitions_count.should == 1
  end

  # -------------------------------------------------------------------------------
  it ": Parse simple_form_for (HAML) 2" do
    # dummy state
    $abst_states = {}
    sc1    = $apv.add_state('controller', 'mailer#create', nil)
    $state = $apv.add_state('view', 'mailer#new', nil)
    $path2id['mailer_path'] = 'C_mailer#create'
    $abst_transitions = {}
    $abst_transitions_count = 0
    $abst_dataflows = {}
    $abst_dataflows_count = 0

    # HAML -> Ruby -> AST
    ruby_code = $apv.conv_haml2ruby(haml_code3)
    sexp = Ripper.sexp(ruby_code)
    # puts haml_code
    # puts ruby_code
    # pp sexp

    $apv.parse_sexp(0, sexp)
    # pp $abst_commands
    # pp $abst_transitions
    # pp $abst_dataflows

    # Submit/ New, Edit ?
    $abst_transitions_count.should eq 1
    $abst_dataflows_count.should eq 2  # TODO: NG
  end

  # ===============================================================================
  # semantic_menu
  # https://github.com/danielharan/semantic-menu
  it ": Parse semantic_menu" do
    #  dummy state
    $abst_states = {}
    sc1    = $apv.add_state('controller', 'hoge#create', nil)
    $state = $apv.add_state('view', 'hoge#hoge', nil)
    $abst_transitions_count = 0
    $abst_transitions = {}

    # ERB -> Ruby -> AST
    ruby_code = Erb::Stripper.new.to_ruby(erb_code4)
    sexp      = Ripper.sexp(ruby_code)
    # DEBUG
    # puts erb_code
    # puts html_out
    # pp sexp

    # Model
    # V ---link_to C_root
    # V ---link_to C_comment#index
    $apv.parse_sexp(0, sexp)
    # DEBUG
    # pp $abst_commands
    # pp $abst_transitions

    # Two link_to trans
    $abst_transitions_count.should eq 2

    # TODO: compleate trans

    # DST
    t = $abst_transitions['T_V_hoge#hoge#0']
    # pp t
    t.src_id.should == 'V_hoge#hoge'
    # t.dst_id.should == 'C_home#index'
    # pp t.dst_hint
  end
end
