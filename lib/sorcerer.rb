# -*- coding: UTF-8 -*-

# Sorcerer
# Generate the original Ruby source from a Ripper-style abstract syntax tree.
# https://rubygems.org/gems/sorcerer
module Sorcerer
  # Generate the source code for teh given Ripper S-Expression.
  def self.source(sexp, debug = false)
    Sorcerer::Resource.new(sexp, debug).source
  end

  # Generate a list of interesting subexpressions for sexp.
  def self.subexpressions(sexp)
    Sorcerer::Subexpression.new(sexp).subexpressions
  end
end

require 'sorcerer/resource'
require 'sorcerer/subexpression'
