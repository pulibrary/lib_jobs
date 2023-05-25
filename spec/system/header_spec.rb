# frozen_string_literal: true
require "rails_helper"

RSpec.describe 'header', js: true do
  before do
    driven_by(:selenium_chrome_headless)
  end
  context 'non-admin user is logged in' do
    it 'shows a log out menu item' do
      user = User.create(email: 'test@example.com')
      login_as(user)
      visit '/'
      within('header') do
        expect(page).to have_link('Log out', visible: false)
      end
    end
  end
  context 'admin user is logged in' do
    it 'shows a link to the feature flipper' do
      user = User.create(email: 'test@example.com')
      allow(user).to receive(:admin?).and_return(true)
      login_as(user)
      visit '/'
      within('header') do
        expect(page).to have_link('Turn jobs on and off', visible: false)
      end
    end
  end
end
