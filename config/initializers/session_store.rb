# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rails-ws_session',
  :secret      => '0c2ecb15e7a9185bc2046f622e9beafce0812062dada122435a6e02f52da9f23d57c7f91b1954d39a313f2463c5bb879fd2d7d3420f59c3d1e19c904465b50b4'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
