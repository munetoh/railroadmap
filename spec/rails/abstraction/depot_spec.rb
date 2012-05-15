#
# Depot app from Agile Web Development with Rails
#
#  https://github.com/tomcz/pragprog-depot-prg   --- Rails 2.3.8 +RSpec/Cucumber
#
# 4th ed. 
#  https://github.com/mitchwd/depot.git          --- Rails 3.1  <<< our base
#  https://github.com/ctshryock/Depot-Rails3     --- Rails 3.1, +sort
#  https://github.com/andyw8/depot               --- Rails 3.2
#
# clone git://github.com/munetoh/depot.git
# cd depot
# 
# brew install postgresql
# bundle install
# rake db:migrate
# rake db:seed
# rake script/load_orders.rb
# rails s

require 'rubygems'
require 'rspec'

require 'rails/abstraction'

require 'pp'

begin
require './spec/rails/abstraction/testenv'
rescue LoadError=> e
  $stderr.puts e.message
  $stderr.puts "create `testenv.rb` file to set"
  exit e.status_code
end

# DEBUG
#require 'tracer'
#Tracer.on

describe Abstraction::MVC do

  it ": global variables " do
    $verbose = 0
    #$verbose = 1  # no filename
    #$verbose = 2
    $robust = false
    
    # Config diagram
    $bsd_display_layout = false
    #$bsd_display_layout = true
  end
  
  it ": Load MVC - depot " do
    #return
    raise "set $depot_basedirs in testenv.rb" if $depot_basedirs == nil
    
    $debug = false
    a = Abstraction::MVC.new($depot_basedirs)
    a.load
    
    a.print_stat if $verbose > 0
    
    #return
    
    # manually set the routes
    a.path2id = {
      'admin_url'     => 'C_admin#index',
      'login_url'     => 'C_session#new',
      'logout_url'    => 'C_session#destroy',
        
      'users_path'     => 'C_user#index',
      'users_url'      => 'C_user#index',
      'new_user_path'  => 'C_user#new',
      'edit_user_path' => 'C_user#edit',
      'user_path'      => 'C_user#show',
      'user'           => 'C_user#show',
      '@user'          => 'C_user#show',
    
      'orders_path'      => 'C_order#index',
      'orders_url'       => 'C_order#index',
      'new_order_path'   => 'C_order#new',
      'edit_order_path'  => 'C_order#edit',
      'order_path'       => 'C_order#show',
      'order'            => 'C_order#show',
      '@order'           => 'C_order#show',
    
      'store_url'            => 'C_store#show',
    
      'line_items_url'      => 'C_line_item#index',
      'line_items_path'     => 'C_line_item#index',
      'new_line_item_path'  => 'C_line_item#new',
      'edit_line_item_path' => 'C_line_item#edit',
      'line_item_path'      => 'C_line_item#show',
      'line_item'           => 'C_line_item#show',
      '@line_item'          => 'C_line_item#show',
    
      'carts_path'      => 'C_cart#index',
      'carts'           => 'C_cart#index',
      'new_cart_path'   => 'C_cart#new',
      'edit_cart_path'  => 'C_cart#edit',
      'cart_path'       => 'C_cart#show',
      'cart'            => 'C_cart#show',
      '@cart'           => 'C_cart#show',
    
      'products_path'     => 'C_product#index',     
      'products_url'      => 'C_product#index',
      'new_product_path'  => 'C_product#new',
      'edit_product_path' => 'C_product#edit',
      'product_path'      => 'C_product#show',
      'product'           => 'C_product#show',
      '@product'          => 'C_product#show',
    }
    
    guard2abst = {
      '' => '',
    }
    a.set_guard_abstmap(guard2abst)
    
    
    # refine block/condition
    a.complete_block
    # refine transition
    a.complete_transition
    
    # Dump     
    a.print_stat if $verbose > 0
    
    # Graphviz
    #a.graphviz('output/depot')
    
    #$bsd_display_layout = true
    #h = Abstraction::Output::Html5.new
    #h.html('output/depot', nil)[
    
    
    Dir::mkdir("output") if File.exists?("output") == false
    Dir::mkdir("output/depot") if File.exists?("output/depot") == false

    h = Abstraction::Output::Html5.new
    h.html('output/depot', nil)
  end  
end