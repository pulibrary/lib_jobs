class EncryptUserEmails < ActiveRecord::Migration[7.2]
  def up
    users =  User.all
    users.each do |user|
      user.encrypt
    end
  end
  def down
   # Needed in the config you're using (production.rb, development.rb)
   # config.active_record.encryption.support_unencrypted_data = true
   users =  User.all
   users.each do |user|
      user.decrypt
    end
  end
end
