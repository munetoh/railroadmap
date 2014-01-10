#  -*- coding: UTF-8 -*-
# Cucumber steps for Railroadmap

# for CSRF attack
When /^(?:|I )press "([^\"]*)" with tampered authenticity_token$/ do |button|
  begin
    field_name = "authenticity_token"
    value = "577adb5c-b8c5-11df-a45c-080027fe0165"
    msg = "cannot set value of hidden field with name '#{field_name}', please check config/environments/test.rb diable CSRF protection or not"
    xpath = %{//input[@type="hidden" and @name="#{field_name}"]}
    page.find(:xpath, xpath, msg).set(value)

    @result = click_button(button)
    rescue => @exception
  end
end

When /^(?:|I )press "([^\"]*)" with missing authenticity_token$/ do |button|
  begin
    field_name = "authenticity_token"
    msg = "cannot set value of hidden field with name '#{field_name}', please check config/environments/test.rb diable CSRF protection or not"
    xpath = %{//input[@type="hidden" and @name="#{field_name}"]}

    page.find(:xpath, xpath, msg).set(value)

    @result = click_button(button)
    rescue => @exception
  end
end

# Rails 3.0.4 raise InvalidAuthenticityToken
# http://stackoverflow.com/questions/5000333/how-does-rails-csrf-protection-work
# your request will be redirected to a login page
#
Then /^(?:|I )should have CSRF error$/ do
  @exception.should be_a_kind_of(ActionController::InvalidAuthenticityToken)
end

# Rails ?
# redirect to home

Then /^show me the page$/ do
  save_and_open_page
end

Given(/^I am on the ([^"]*)$/) do |path|
  visit path
end

Given(/^a logged in user$/) do
  create_user
  sign_in
end
