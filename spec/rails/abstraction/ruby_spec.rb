# -*- coding: UTF-8 -*-
#
# TODO: v010 => v02X
#

# Test for
#   Ruby -> AST
#   ERB  -> AST
#   Haml -> AST
#
# rspec --color spec/rails/abstraction/ruby_spec.rb
#
require 'spec_helper'

describe Abstraction::Parser::View do

  it ": Parse ERB" do
    erb = "<%= link_to 'Back', tags_path %>"

    # ERB -> Ruby
    ruby = Erb::Stripper.new.to_ruby(erb)

    # Ruby -> AST
    s = Ripper.sexp(ruby)

    # AST -> Ruby
    a = Sorcerer.source(s)

    # TODO: remove ','
    a.should eq "link_to \"Back\", tags_path, , "
  end
end

describe Abstraction::MVC do
  # get_assoc(sexp, 'action')
  it ": Parse AST - assoc " do
    bdir = './'
    m = Abstraction::MVC.new

    ruby = "render :hoge => \"hoge\", :action => \"new\""
    sexp = Ripper.sexp(ruby)
    id = m.get_assoc(sexp[1][0][2], 'action')

    id.should eq 'new'
    ruby = "render :new"
    sexp = Ripper.sexp(ruby)
    id = m.get_assoc(sexp[1][0][2], 'action')
    id.should eq 'new'

    ruby = "render \"new\""
    sexp = Ripper.sexp(ruby)
    id = m.get_assoc(sexp[1][0][2], 'action')
    id.should eq 'new'
  end
end

describe Abstraction::Parser::AstParser do
  it ": Parse AST - get_hash " do
    p = Abstraction::Parser::AstParser.new

    ruby = "ssl_required :new, :create, :destroy, :update"
    sexp = Ripper.sexp(ruby)

    l = p.get_hash(sexp[1][0][2])

    l['new'].should be_true
    l['create'].should be_true
    l['destroy'].should be_true
    l['update'].should be_true
    l['hoge'].should be_nil
  end

  it ": Parse AST - get_assoc_hash" do
    p = Abstraction::Parser::AstParser.new

    # Ruby -> AST
    ruby = "before_filter :authenticate_user!, :only => [:edit, :update, :destroy]"
    sexp = Ripper.sexp(ruby)

    # assoc_hash -> Hash
    a = sexp[1][0][2][1][1][1][0]
    l = p.get_assoc_hash_list('only', a)

    l['edit'].should be_true
    l['update'].should be_true
    l['destroy'].should be_true
  end

  #
  # #<RuntimeError: Handler for @label not implemented ([:@label, "confirm:", [18, 40]])>
  # redirect_to login_url, notice: "Please log in"
  #
  it ": Parse AST - @label" do
    p = Abstraction::Parser::AstParser.new

    # Ruby -> AST
    ruby = "redirect_to login_url, notice: \"Please log in\""
    sexp = Ripper.sexp(ruby)

    # AST -> Ruby
    ruby2 = p.get_ruby(sexp)

    # ruby2.should eq ruby
    # TODO: not exactly the same
    ruby2.should eq  "redirect_to login_url, notice: => \"Please log in\", , "
  end
end
