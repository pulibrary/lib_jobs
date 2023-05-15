require 'rails_helper'

RSpec.describe AspaceSvn::GetEadsJob do
  describe "report" do
    it "reports success" do
      expect(described_class.new.report).to eq "EADs successfully exported."
    end
  end
end
