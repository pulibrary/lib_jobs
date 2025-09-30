# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AspaceVersionControl::GitLab do
  it 'can access configuration' do
    expect(described_class.git_uri).to eq('git@gitlab-staging-vm.lib.princeton.edu:mk8066/test-project-for-cloning.git')
    expect(described_class.git_repo_path).to eq('tmp/gitlab_eads')
  end
  context 'calling original methods' do
    let(:repo) { Git.init('tmp/gitlab_eads') }

    context 'without a repository already cloned' do
      before do
        FileUtils.rm_rf('tmp/gitlab_eads')
      end
      it 'can instantiate a repository' do
        allow(Git).to receive(:clone).and_return(repo)
        allow(Git).to receive(:open)
        git_lab = described_class.new
        expect(git_lab.repo).to be_an_instance_of(Git::Base)
        git_lab.repo
        expect(Git).to have_received(:clone)
        expect(Git).not_to have_received(:open)
      end
    end
    context 'with a previously cloned repository' do
      before do
        FileUtils.rm_rf('tmp/gitlab_eads')
        repo
      end

      it 'can instantiate a repository' do
        allow(Git).to receive(:clone).and_raise(Git::Error)
        allow(Git).to receive(:open).and_return(repo)
        git_lab = described_class.new
        expect(git_lab.repo).to be_an_instance_of(Git::Base)
        git_lab.repo
        expect(Git).to have_received(:clone)
        expect(Git).to have_received(:open)
      end

      it 'can update from the repository' do
        allow(Git).to receive(:clone).and_return(repo)
        allow(repo).to receive(:pull).and_return("Already up to date.")
        allow(repo).to receive(:checkout).and_return("Updated 0 paths from")
        git_lab = described_class.new
        git_lab.update
        expect(repo).to have_received(:pull)
        expect(repo).to have_received(:checkout).with('HEAD')
      end
      context 'with no changes' do
        before do
          repo.reset_hard
        end

        it 'does not attempt to add, commit, or push' do
          allow(Rails.logger).to receive(:info)
          allow(Git).to receive(:clone).and_return(repo)
          allow(repo).to receive(:pull).and_return("Already up to date.")
          allow(repo).to receive(:add).and_call_original
          allow(repo).to receive(:commit).and_call_original
          allow(repo).to receive(:push).and_call_original
          allow(repo).to receive(:checkout).and_return("Updated 0 paths from")
          described_class.new.commit_eads_to_git(path: 'testing')
          expect(repo).to have_received(:pull)
          expect(repo).not_to have_received(:add)
          expect(repo).not_to have_received(:commit)
          expect(repo).not_to have_received(:push)
          expect(repo).to have_received(:checkout).with('HEAD')
          expect(Rails.logger).to have_received(:info)
        end
      end
      context 'with changes' do
        before do
          FileUtils.touch('tmp/gitlab_eads/testing')
        end
        after do
          repo.reset_hard
        end
        it 'can add changes to a commit' do
          allow(Git).to receive(:clone).and_return(repo)
          allow(repo).to receive(:add).and_return("")
          git_lab = described_class.new
          git_lab.add(path: 'testing')
          expect(repo).to have_received(:add).with('testing')
        end

        context 'with changes pushed' do
          after do
            FileUtils.rm_rf('tmp/gitlab_eads/testing')
            repo.add
            repo.commit('removing changes for testing')
            repo.push
          end

          it 'has a parallel API to svn' do
            allow(Git).to receive(:clone).and_return(repo)
            allow(repo).to receive(:pull).and_return("Already up to date.")
            allow(repo).to receive(:add).and_return("")
            allow(repo).to receive(:commit).and_return("[main b1b385c] monthly snapshot of ASpace EADs\n 1 file changed, 0 insertions(+), 0 deletions(-)\n create mode 100644 testing")
            allow(repo).to receive(:push).and_return(nil)
            allow(repo).to receive(:checkout).and_return("Updated 0 paths from")
            described_class.new.commit_eads_to_git(path: 'testing')
            expect(repo).to have_received(:add).with('testing')
            expect(repo).to have_received(:commit).with('monthly snapshot of ASpace EADs')
            expect(repo).to have_received(:push)
            expect(repo).to have_received(:checkout).with('HEAD')
          end
        end
      end
    end
  end
end
