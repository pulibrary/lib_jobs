# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Gobi::IsbnReportJob, type: :model do
  include_context 'sftp'
  let(:isbn_job) { described_class.new }

  it_behaves_like 'a lib job'
  it 'can be instantiated' do
    expect { described_class.new }.not_to raise_error
  end

  it 'can be run' do
    expect(isbn_job.run).to be_truthy
  end
end
