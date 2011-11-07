require 'acts_as_subscribable/acts_as_subscribable'
require 'acts_as_subscribable/subscription'
require 'acts_as_subscribable/acts_as_subscriber'

ActiveRecord::Base.extend ActsAsSubscribable::ActMethod
ActiveRecord::Base.extend ActsAsSubscriber::ActMethod