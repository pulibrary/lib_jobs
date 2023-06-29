# frozen_string_literal: true
require "rails_helper"

describe "accessibility", type: :system, js: true do
  context "home page" do
    before do
      visit "/"
    end

    it "complies with wcag" do
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding('duplicate-id-aria') # https://github.com/pulibrary/lib_jobs/issues/538 
        .excluding('.lux-main-menu-list') # https://github.com/pulibrary/lib_jobs/issues/541
    end
  end
end
