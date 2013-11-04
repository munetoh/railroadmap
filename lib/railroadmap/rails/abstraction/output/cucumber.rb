# -*- coding: UTF-8 -*-
# Testcase
#

module Abstraction
  module Output
    # BDD: CUcumber/RSpec
    class Cucumber

      # STEP def
      def gensteps(filename)
        open(filename, "w") do |f|
          f.write <<-EOF
When /^I access "(.*?)"$/ do |path|
  #pending # express the regexp above with the code you wish you had
  visit path
end

Then /^I should see "(.*?)" message$/ do |message|
  #pending # express the regexp above with the code you wish you had
  page.should have_content  message
end
EOF
        end # do
      end

      def geturl(id)
        path = $path2id.key(id)
        if path.nil?
          $log.error "no path for #{id}, skip test"
          return nil
        end
        path = path.gsub('@', '')

        begin
          url = $route_map[path][0]
        rescue => e
          p id
          p path
          raise e
        end

        url = url.gsub(':id', '1')
        return url
      end

      # TODO
      def getmsg(id)
        # TODO: move to req
        map = {
          'C_devise:password#new' => 'Forgot your password?',
          'C_devise:password#edit' => "You can\'t access this page without coming from a password reset email.",
          'C_devise:registration#new' => 'Forgot your password?',
          'C_devise:registration#cancel' => 'Forgot your password?',
          'C_devise:session#new' => 'Forgot your password?',
          'C_devise:session#create' => 'Forgot your password?',
          'C_devise:session#destroy' => 'Login', # TODO
        }
        msg = map[id]
        msg = "You need to sign in or sign up before continuing." if msg.nil?
        return msg
      end

      def output_anon(dir)
        file = dir + '/anon_attack.feature'
        open(file, "w") do |f|
          f.write "@attack\n"
          f.write "Feature: Attack by Anonymous\n"
          f.write "As an anonymous user of the website, I want to access protected resources\n"

          $attacks.each do |a|
            if a.type == 'unauthenticated_access'
              path = geturl(a.trans.dst_id)
              msg = getmsg(a.trans.dst_id)
              unless path.nil?
                f.write "  Scenario: I access #{path} (id=#{a.trans.dst_id})\n"
                f.write "    Given I do not exist as a user\n"
                f.write "    When I access \"#{path}\"\n"
                f.write "    Then I should see \"#{msg}\" message\n"
                f.write "\n"
              end
            end
          end
        end # do
      end

      def output_user(dir)
        file = dir + '/user_attack.feature'
        open(file, "w") do |f|
          f.write "@attack\n"
          f.write "Feature: Attack by User\n"
          f.write "As a registered user of the website, I want to access protected resources\n"
          $attacks.each do |a|
            if a.type == 'unauthorized_access'
              path = geturl(a.trans.dst_id)
              unless path.nil?
                f.write "  Scenario: I sign in and access #{path}\n"
                f.write "    Given I am logged in\n"
                f.write "    When I access \"#{path}\"\n"
                f.write "    Then I should see \"Not authorized as an administrator.\" message\n"
                f.write "\n"
              end
            end
          end
        end # do
      end

      def output(dir)
        # TODO: check $attacks
        puts "  #{$attacks.size} attacks"
        # Anon
        output_anon(dir)
        # User
        output_user(dir)
        # TODO: XSS
        # TODO: CSRF
        # TODO: MassAssignment
      end
    end
  end
end
