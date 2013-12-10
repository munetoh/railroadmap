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

require 'rubygems'
require 'rspec'

require 'railroadmap/rails/abstraction'
require 'pp'

# Logging
require 'logger'
$log = Logger.new(STDOUT)
$log.level = Logger::ERROR
$log.formatter = proc do |severity, datetime, progname, msg|
  if severity == 'ERROR' || severity == 'INFO' || severity == 'DEBUG'
    position = caller.at(4).sub(%r{.*/}, '').sub(%r{:in\s.*}, '')
    "#{severity} #{position} #{msg}\n"
  else
    "#{severity} #{msg}\n"
  end
end

# Global
$block_var = []
$abst_commands = {}
$unknown_command = 0
$abst_states = {}
$abst_transitions = {}
$route_map = {}
$abst_transitions_count = 0
$path2id = {}
$abst_dataflows = {}
$abst_dataflows_count = 0

# Command library
$rails_command_list = {
  'text_field' => {
     type:       'dataflow',
     subtype:    'output',
     providedby: 'rails',
  },
  'label' => {
     type:       'dataflow',
     subtype:    'output',
     providedby: 'rails',
  },

  'form_for' => {
     type:       'input_dataflow',  # form_for form_tag
     subtype:    'form',
     providedby: 'rails',
  },

  # simple_form
  'simple_form_for' => {
     type:       'input_dataflow',  # form_for form_tag
     subtype:    'form',
     providedby: 'simple_form',
  },
  'input' => {
     type:       'dataflow',  # form_for form_tag
     subtype:    'input',
     providedby: 'rails',
  },

  'button' => {
     type:       'transition',  # form_for form_tag
     subtype:    'post',
     providedby: 'rails',
  },

  # semantic_menu
  'semantic_menu' => {
     type:       'input_dataflow',  # form_for form_tag
     subtype:    'form',
     providedby: 'semantic_menu',
  },

  'add' => {
     type:       'transition',  # link_to
     subtype:    'link_to',
     providedby: 'semantic_menu',
  },
}

describe Abstraction::Parser::Controller do

  # ===============================================================================
  # form_for
  # http://apidock.com/rails/ActionView/Helpers/FormHelper/form_for
  it ": Parse form_for (ERB)" do
    apv = Abstraction::Parser::View.new

    #  dummy state
    $abst_states = {}
    sc1    = apv.add_state('controller', 'offer#create', nil)
    $state = apv.add_state('view', 'offer#new', nil)

    apv.add_command_list($rails_command_list)
    $abst_transitions_count = 0
    $abst_transitions = {}
    # $form_target = 'hoge'  # set by lib/railroadmap/rails/rails-commands.rb => TODO generic? by AST side
    $form_target = nil

    erb_code = <<"EOS"
<%= form_for @offer do |f| %>
  <%= f.label :version, 'Version' %>:
  <%= f.text_field :version %><br />
  <%= f.label :author, 'Author' %>:
  <%= f.text_field :author %><br />
  <%= f.submit %>
<% end %>
EOS

    # ERB -> Ruby -> AST
    ruby_code = Erb::Stripper.new.to_ruby(erb_code)
    sexp = Ripper.sexp(ruby_code)
    # pp sexp

    apv.parse_sexp(0, sexp)

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
    apv = Abstraction::Parser::View.new

    #  dummy state
    $abst_states = {}
    sc1    = apv.add_state('controller', 'offer#create', nil)
    $state = apv.add_state('view', 'offer#new', nil)
    # apv.add_command_list($rails_command_list)
    $abst_transitions_count = 0
    $abst_transitions = {}

    haml_code = <<"EOS"
= form_for @offer do |f|
  = f.label :version, 'Version'
  = f.text_field :version
  = f.label :author, 'Author'
  = f.text_field :author
  = f.submit
EOS

    # HAML -> Ruby -> AST
    ruby_code = apv.conv_haml2ruby(haml_code)
    # puts ruby_code
    sexp = Ripper.sexp(ruby_code)

    apv.parse_sexp(0, sexp)

    # pp $abst_commands
    # pp $abst_transitions

    # Submit/ New, Edit ?
    $abst_transitions_count.should eq 1
  end
  # ===============================================================================
  # simple_form_for
  # https://github.com/plataformatec/simple_form
  it ": Parse simple_form_for (ERB)" do
    apv = Abstraction::Parser::View.new

    # dummy state
    $abst_states = {}
    sc1 = apv.add_state('controller', 'user#update', nil)

    $state = apv.add_state('view', 'user#edit', nil)
    # apv.add_command_list($rails_command_list)
    $abst_transitions_count = 0
    $abst_transitions = {}
    $form_target = 'hoge'

    erb_code = <<"EOS"
<%= simple_form_for @user do |f| %>
  <%= f.input :username %>
  <%= f.input :password %>
  <%= f.button :submit %>
<% end %>
EOS

    # ERB -> Ruby -> AST
    ruby_code = Erb::Stripper.new.to_ruby(erb_code)
    sexp = Ripper.sexp(ruby_code)
    # pp sexp

    apv.parse_sexp(0, sexp)
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
    apv = Abstraction::Parser::View.new

    #  dummy state
    $abst_states = {}
    sc1 = apv.add_state('controller', 'user#create', nil)
    $state = apv.add_state('view', 'user#new', nil)
    # apv.add_command_list($rails_command_list)
    $abst_transitions_count = 0
    $abst_transitions = {}

    haml_code = <<"EOS"
=simple_form_for @user do |f|
  .inputs
    =f.input :username
    =f.input :password
  .actions
    =f.button :submit
EOS

    # HAML -> Ruby -> AST
    ruby_code = apv.conv_haml2ruby(haml_code)
    # puts haml_code
    # puts ruby_code

    sexp = Ripper.sexp(ruby_code)
    # pp sexp

    apv.parse_sexp(0, sexp)
    # pp $abst_commands
    # pp $abst_transitions

    # Submit/ New, Edit ?
    $abst_transitions_count.should == 1
  end

  # -------------------------------------------------------------------------------
  it ": Parse simple_form_for (HAML) 2" do
    apv = Abstraction::Parser::View.new

    # dummy state
    $abst_states = {}
    sc1 = apv.add_state('controller', 'mailer#create', nil)
    $state = apv.add_state('view', 'mailer#new', nil)
    # apv.add_command_list($rails_command_list)

    $path2id['mailer_path'] = 'C_mailer#create'

    $abst_transitions = {}
    $abst_transitions_count = 0
    $abst_dataflows = {}
    $abst_dataflows_count = 0

    haml_code = <<"EOS"
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

    # HAML -> Ruby -> AST
    ruby_code = apv.conv_haml2ruby(haml_code)
    # puts haml_code
    # puts ruby_code

    sexp = Ripper.sexp(ruby_code)
    # pp sexp

    apv.parse_sexp(0, sexp)
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
    apv = Abstraction::Parser::View.new

    #  dummy state
    $abst_states = {}
    sc1 = apv.add_state('controller', 'hoge#create', nil)
    $state = apv.add_state('view', 'hoge#hoge', nil)
    # apv.add_command_list($rails_command_list)
    $abst_transitions_count = 0
    $abst_transitions = {}

    erb_code = <<"EOS"
<%= semantic_menu do |root|
  root.add "overview", root_path
  root.add "comments", comments_path
end %>
EOS

    html_out = <<"EOS"
<ul class="menu">
  <li>
    <a href="/">overview</a>
  </li>
  <li class="active">
    <a href="/comments">comments</a>
  </li>
</ul>
EOS

    # ERB -> Ruby -> AST
    ruby_code = Erb::Stripper.new.to_ruby(erb_code)
    sexp = Ripper.sexp(ruby_code)
    # DEBUG
    # puts erb_code
    # puts html_out
    # pp sexp

    # Model
    # V ---link_to C_root
    # V ---link_to C_comment#index
    apv.parse_sexp(0, sexp)
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
