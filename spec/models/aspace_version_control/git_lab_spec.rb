# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AspaceVersionControl::GitLab do
  it 'can access configuration' do
    expect(described_class.git_uri).to eq('git@gitlab-staging-vm.lib.princeton.edu:mk8066/test-project-for-cloning.git')
    expect(described_class.git_repo_path).to eq('tmp/gitlab_eads')
    expect(described_class.git_repo_eacs_path).to eq('tmp/gitlab_eacs')
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
        allow(repo).to receive(:reset_hard).and_return("Updated 0 paths from")
        git_lab = described_class.new
        git_lab.update
        expect(repo).to have_received(:pull)
        expect(repo).to have_received(:reset_hard)
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
          described_class.new.commit_eads_to_git(path: 'testing')
          expect(repo).to have_received(:pull)
          expect(repo).not_to have_received(:add)
          expect(repo).not_to have_received(:commit)
          expect(repo).not_to have_received(:push)
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
            described_class.new.commit_eads_to_git(path: 'testing')
            expect(repo).to have_received(:add).with('testing')
            expect(repo).to have_received(:commit).with('monthly snapshot of ASpace EADs')
            expect(repo).to have_received(:push)
          end
        end
      end
    end
  end

  context 'with custom repo path for EACs' do
    let(:eacs_repo) { Git.init('tmp/gitlab_eacs') }
    let(:custom_git_lab) { described_class.new(repo_path: 'tmp/gitlab_eacs') }

    before do
      FileUtils.rm_rf('tmp/gitlab_eacs')
      eacs_repo
    end

    after do
      FileUtils.rm_rf('tmp/gitlab_eacs')
    end

    it 'uses custom repo path instead of default' do
      allow(Git).to receive(:clone).and_raise(Git::Error)
      allow(Git).to receive(:open).and_return(eacs_repo)

      expect(custom_git_lab.current_repo_path).to eq('tmp/gitlab_eacs')
      expect(custom_git_lab.repo).to be_an_instance_of(Git::Base)
      expect(Git).to have_received(:open).with('tmp/gitlab_eacs')
    end

    context 'commit_eacs_to_git method' do
      context 'with no changes' do
        before do
          eacs_repo.reset_hard
        end

        it 'does not attempt to add, commit, or push for EACs' do
          allow(Rails.logger).to receive(:info)
          allow(Git).to receive(:clone).and_return(eacs_repo)
          allow(eacs_repo).to receive(:pull).and_return("Already up to date.")
          allow(eacs_repo).to receive(:add).and_call_original
          allow(eacs_repo).to receive(:commit).and_call_original
          allow(eacs_repo).to receive(:push).and_call_original
          allow(eacs_repo).to receive(:config).and_return(nil)

          custom_git_lab.commit_eacs_to_git(path: 'eacs')

          expect(eacs_repo).to have_received(:pull)
          expect(eacs_repo).not_to have_received(:add)
          expect(eacs_repo).not_to have_received(:commit)
          expect(eacs_repo).not_to have_received(:push)
          expect(Rails.logger).to have_received(:info)
        end
      end

      context 'with changes' do
        before do
          FileUtils.mkdir_p('tmp/gitlab_eacs')
          FileUtils.touch('tmp/gitlab_eacs/test_agent.cpf.xml')
        end

        after do
          eacs_repo.reset_hard
        end

        it 'commits EACs with appropriate message' do
          allow(Git).to receive(:clone).and_return(eacs_repo)
          allow(eacs_repo).to receive(:pull).and_return("Already up to date.")
          allow(eacs_repo).to receive(:add).and_return("")
          # rubocop:disable Layout/LineLength:
          allow(eacs_repo).to receive(:commit).and_return("[main abc123] monthly snapshot of ASpace Agent EACs\n 1 file changed, 0 insertions(+), 0 deletions(-)\n create mode 100644 test_agent.cpf.xml")
          # rubocop:enable Layout/LineLength:
          allow(eacs_repo).to receive(:push).and_return(nil)
          allow(eacs_repo).to receive(:config).and_return(nil)

          custom_git_lab.commit_eacs_to_git(path: 'eacs')

          expect(eacs_repo).to have_received(:add).with('eacs')
          expect(eacs_repo).to have_received(:commit).with('monthly snapshot of ASpace Agent EACs')
          expect(eacs_repo).to have_received(:push)
        end
      end
    end
  end
end
