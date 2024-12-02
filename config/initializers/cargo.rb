# frozen_string_literal: true
Dir.chdir(Rails.root.join("lib_jobs_rs")) do
  `cargo build --release`
end
