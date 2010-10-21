# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_torrent_dam_session',
  :secret      => '7719b740c64ba47fbab990514a776c5bf217f24234cdc33213fd8a2b91f50e736afd3b8e8dc05ed973932146d156b59b4f3e54225ad5afa322338292cfc64837'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
