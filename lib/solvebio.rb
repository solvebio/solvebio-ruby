# -*- coding: utf-8 -*-
# Something to pull in the entire SolveBio API.

require_relative 'resource'
require_relative 'query'

# cli/auth is a little nicer than credentials
# FIXME: consider moving cli/auth moving out of cli?
require_relative 'cli/auth'

# Set authentication if possible
include SolveBio::Credentials
creds = get_credentials()
SolveBio.api_key = SolveBio::Client.client.api_key = creds[1] if creds
