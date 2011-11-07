module ActsAsSubscriber #:nodoc:
  module ActMethod
    def acts_as_subscriber
      has_many :subscriptions, :dependent => :destroy
    end
  end
end