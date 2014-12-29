require 'bundler/setup'
require 'active_support'
require 'active_support/testing/autorun'

require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'
require 'json'
require 'openssl'

require 'tokie'

ActiveSupport::TestCase.test_order = :random

SECRET = 'forYOURsecretforYOURsecretforYOURsecret'
Tokie.secret = SECRET
