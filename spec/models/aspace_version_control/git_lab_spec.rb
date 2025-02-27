# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AspaceVersionControl::GitLab do
  let(:git_double) { Git.init('tmp/gitlab_eads') }

  context 'with a double' do
    before do
      FileUtils.rm_rf('tmp/gitlab_eads')
      git_double.add_remote('testing', Git::Base)
      allow(git_double).to receive(:pull)
      allow(Git).to receive(:open).and_return(git_double)
      allow(Git).to receive(:clone).and_return(git_double)
    end

    it 'has the same api as the Svn class' do
      allow(Git).to receive(:open).and_return(git_double)
      described_class.new.commit_eads_to_git(path: 'mudd/publicpolicy')
    end

    it 'pulls the repository' do
      allow(git_double).to receive(:pull)
      described_class.new.commit_eads_to_git(path: 'mudd/publicpolicy')
      expect(git_double).to have_received(:pull)
    end
  end

  context 'with a real repository' do
    let(:git_double) { Git.clone('git@gitlab-staging-vm.lib.princeton.edu:mk8066/test-project-for-cloning', 'tmp/gitlab_eads') }

    before do
      FileUtils.rm_rf('tmp/gitlab_eads')
      allow(Git).to receive(:open).and_return(git_double)
      allow(Git).to receive(:clone).and_return(git_double)
    end

    it 'can pull' do
      
      allow(git_double).to receive(:pull).and_call_original
      described_class.new.commit_eads_to_git(path: 'mudd/publicpolicy')
      expect(git_double).to have_received(:pull)
    end
  end

  context 'without the destination directory' do
    before do
      FileUtils.rm_rf('tmp/gitlab_eads')
      git_double.add_remote('testing', Git::Base)

    end

    it 'clones the repository' do
      allow(Git).to receive(:clone).and_return(git_double)
      described_class.new.commit_eads_to_git(path: 'mudd/publicpolicy')
      expect(Git).to have_received(:clone)
    end
  end

  context 'with the destination directory' do
    before do
      FileUtils.rm_rf('tmp/gitlab_eads')
      FileUtils.mkdir_p 'tmp/gitlab_eads'
      Git.init('tmp/gitlab_eads')
    end

    it 'tries to clone the directory' do
      allow(Git).to receive(:clone).and_return(git_double)
      described_class.new.commit_eads_to_git(path: 'mudd/publicpolicy')
      expect(Git).to have_received(:clone)
    end
    it 'opens the directory' do
      allow(Git).to receive(:open).and_return(git_double)
      described_class.new.commit_eads_to_git(path: 'mudd/publicpolicy')
      expect(Git).to have_received(:open)
    end
  end
end
