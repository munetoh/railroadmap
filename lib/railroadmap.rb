# -*- coding: UTF-8 -*-

libdir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# $:.unshift(File.dirname(__FILE__)) unless
#  $:.include?(File.dirname(__FILE__)) ||
#    $:.include?(File.expand_path(File.dirname(__FILE__)))

# RailroadMap
module Railroadmap
  VERSION = '0.2.1'
end
