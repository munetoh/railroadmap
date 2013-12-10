# -*- coding: UTF-8 -*-
# Dashboard class -- sum all results!
#
# Summarize
#   - Warnings
#   - Errors
#   - Nav. and DF. Model
#
# Export?
#   - to HTML (default)
#   - to JSON
#   - to DOT => Graphviz
#   - to B model => ProB etc
#
# HTML output
#
# 2012-07-16  new version based on ERB
# 2013-03-03  TODO move to new class, lib/dashboard.rb?
#
# Follow the style of simplecov and simplecov-html
#
#  ERB(./view/*)            => railroadmap/index.html
#  JS(./public/*.js, *.css) => railroadmap/asset
#
# How to update?
#  1) lib/security-assuarance-model.rb  add class/def
#  2) views/layout.erb                  add tab
#  3) This html.rb                      add def
#  X) public/application.css            X_list
#
#
#  Base Class
#    lib/security-asuarance-model.rb  =>smodel
#
#  ERBs
#    views/layout.erb      top
#    views/dashboard.erb   Dashboard tab
#    views/warning.erb     Warinigns tab
#    views/design.erb      Design tab (ACL, Asset)
#    views/navmodel.erb    Navigation model tab (Transitions)
#
#    views/rational.erb    Rational tab  asset-req-code-test
#    views/diagram.erb     Diagram tab
#
#   HTML5
#    public/application.js
#    public/application.css
#
#  Dataflow
#    security-assuarance-model.rb
#        html.rb(this) -> views/layout.erb -> views/*.erb  ---> railroadmap/index.html
#
#
require 'erb'
require 'cgi'
require 'fileutils'
require 'digest/sha1'
require 'time'

#  module Abstraction
#  module Output
class Dashboard
  # init
  def initialize
    @output_path = './railroadmap'
    @asset_output_path = './railroadmap/assets'  # JS
  end

  # format
  def format(smodel)
    $log.debug "Dashboard.format"

    Dir.mkdir(@asset_output_path) if File.exist?(@asset_output_path) == false

    # Copy javascript
    Dir[File.join(File.dirname(__FILE__), 'templates/assets')].each do |path|
      FileUtils.cp_r(path, @output_path)
    end

    # index.html
    File.open(File.join(@output_path, "index.html"), "w+") do |file|
      file.puts template('layout').result(binding)
    end
  end

  # TBD
  def output_message(result)
    # "Coverage report generated for #{result.command_name} to #{output_path}. #{result.covered_lines} / #{result.total_lines} LOC (#{result.covered_percent.round(2)}%) covered."
  end

  # name
  def project_name
    'TBD'  # TODO: set application name
  end

  # path
  def assets_path(name)
    File.join('./assets', name)
  end

  # CSS: covered_percent => color
  def coverage_css_class(covered_percent)
    if covered_percent > 90
      'green'
    elsif covered_percent > 80
      'yellow'
    else
      'red'
    end
  end

  def warning_css_class(count)
    if count == 0
      'green'
    else
      'red'
    end
  end

  def errors_css_class(count)
    if count == 0
      'green'
    else
      'red'
    end
  end

  def errors_css_tr_class(count)
    if count == 1
      'green'
    else
      'red'
    end
  end

  def unclear_css_tr_class(flag, msg)
    if flag
      "class=\"error_bg\" title=\"#{msg}\""
    else
      "class=\"black\""
    end
  end

  def unclear_css_class(flag)
    if flag
      'red'
    else
      'black'
    end
  end

  def public_css_class(flag)
    if flag
      'public_bg'
    else
      'black'
    end
  end

  # .is_unclear_authentication, s.is_unclear_authorization, s.is_unclear_pdp, s.is_public
  def asset_css_tr_class(s)
    unclear_flag = false
    msg = ""
    if s.code_policy.is_unclear_authentication
      unclear_flag = true
      msg += "Unclear authentication, "
    end
    if s.code_policy.is_unclear_authorization
      unclear_flag = true
      msg += "Unclear authorization, "
    end
    if s.code_policy.is_unclear_pdp
      unclear_flag = true
      msg += "no role"
    end

    if unclear_flag
      "class=\"error_bg\" title=\"#{msg}\""
    elsif s.code_policy.is_public
      "class=\"public_bg\" title=\"public\""
    else
      "class=\"black\""
    end
  end

  # time
  def timeago(time)
    "<abbr class=\"timeago\" title=\"#{time.iso8601}\">#{time.iso8601}</abbr>"
  end

  #------------------------------------------------------------------------
  # Tabs

  # Dashboard Tab
  def dashboard(title, smodel)
    weaknesses = smodel.weaknesses
    # TODO: calc  coverage
    coverage = 0
    template('dashboard').result(binding)
  end

  # Warning Tab call from layout.erb
  #   warnings          Array
  #   warning_count     int   (remove FP)
  #   brakeman_warnings Array
  def warning(title, smodel)
    warnings = smodel.warnings
    railroadmap_warning_count = warnings.size

    errors = smodel.errors
    railroadmap_errors_count = smodel.errors_count

    brakeman_warnings = smodel.brakeman_warnings
    brakeman_warning_count = brakeman_warnings.size

    total_warning_count = railroadmap_warning_count + brakeman_warning_count
    template('warning').result(binding)
  end

  # Design Tab
  def design(title, smodel)
    design = smodel.design
    # TODO: calc  coverage
    template('design').result(binding)
  end

  # navigation model (table) Tab
  def navmodel(title, smodel)
    # TODO: calc  coverage
    transitions = smodel.transitions
    variables = smodel.variables
    dataflows = smodel.dataflows
    raw_out_count = smodel.raw_out_count
    downsteram_policy_count = smodel.downsteram_policy_count

    # TODO: Trans
    unclear = 0
    transitions.each do |n, t|
      unclear += t.setup4dashboard
    end
    template('navmodel').result(binding)
  end

  # navigation model (rational) Tab
  def navigation(title, rationals)
    template('navigation').result(binding)
  end

  # navigation model Tab
  def abuse(title, rationals)
    template('abuse').result(binding)
  end

  # Diagram tab
  def diagram(title, attacks)
    template('diagram').result(binding)
  end

  # file list
  def formatted_file_list(title, source_files)
    template('file_list').result(binding)
  end

  # CSS: covered_strength => color
  def strength_css_class(covered_strength)
    if covered_strength > 1
      'green'
    elsif covered_strength == 1
      'yellow'
    else
      'red'
    end
  end

  # Returns the an erb instance for the template of given name
  def template(name)
    file = File.join(File.dirname(__FILE__), 'templates/', "#{name}.erb")
    $log.info " load ERB template #{file} => parse"
    ERB.new(File.read(file))
  end
end # HTML
