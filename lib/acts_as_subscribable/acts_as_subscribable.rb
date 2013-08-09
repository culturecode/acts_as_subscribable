module ActsAsSubscribable
  module ActMethod #:nodoc:
    # This +acts_as+ extension allows objects to create subscriptions
    # These subscriptions can be used to notify interested users something interesting happens to the object.
    #
    # example:
    #
    # class ItemUserTag < ActiveRecord::Base
    #   acts_as_subscribable
    # end
    #

    # Configuration options are:
    #
    # * +subscription_name+ - specifies the name of the subscription used for display in the view (default is class name)
    # * +user_id+ - specifies how to get the id of the user who caused the subscription to be created. (default is calling user.id)
    def acts_as_subscribable(options = {})
      has_many :subscriptions, :as => :subscribable, :dependent => :destroy
      has_many :subscribers, :through => :subscriptions, :source => :user
      
      scope :subscribed_to_by, lambda{|user| joins(:subscriptions).where(:subscriptions => {:user_id => user.id})}

      attr_accessor :subscribe_creator      # when true, subscribes the creator of the subscribable automatically
      attr_accessor :subscribe_updater      # when true, subscribes users who comment on this subscribable automatically
      attr_accessor :notify_on_update       # when true, notifies all users subscribed to this subscribable when a comment is attached to it

      after_create :subscribe_self
      
      # Define how to retrieve the user who created the subscribable
      # We need this when creating a subscribable with subscribe_creator = true
      class_eval <<-EOV
        def subscribable_user
          #{options[:user] || 'user'}
        end
      EOV

      extend ActsAsSubscribable::ClassMethods
      include ActsAsSubscribable::InstanceMethods
    end
  end

  module ClassMethods
    # Find all the subscriptions of the subscribables by the user in a single SQL query and cache them in the subscribables for use in the view.
    def cache_subscriptions_for(subscribables, user)
      subscriptions = []
      Subscription.where(:subscribable_type => name, :subscribable_id => subscribables.collect(&:id), :user_id => user.id).each do |subscription|
        subscriptions[subscription.subscribable_id] = subscription
      end

      for subscribable in subscribables
        subscribable.cached_subscription = subscriptions[subscribable.id] || false
      end
      
      return subscribables
    end
  end

  module InstanceMethods
    attr_accessor :cached_subscription

    def is_subscribable?
      true
    end

    def subscribe(user)
      Subscription.where(:user_id => user.id, :subscribable_type => self.class.to_s, :subscribable_id => id).first_or_create!
    end

    def subscribe_self
      subscribe(subscribable_user) unless subscribe_creator.eql? false
    end

    def notify_of_update(mailer_action, initiator, message = '')
      UserMailer.send(mailer_action + "_email", subscribers - [initiator], self, message, initiator).deliver unless notify_on_update.eql? false
      subscribe(initiator) unless subscribe_updater.eql? false
    end

    def subscribed_to_by?(user)
      case cached_subscription
      when nil
        subscribers.loaded? ? subscribers.include?(user) : subscribers.exists?(user)
      else
        cached_subscription
      end
    end

    def subscription_by(user)
      case cached_subscription
      when nil
        subscriptions.find_by_user_id(user.id)
      when false
        nil
      else
        cached_subscription
      end
    end
  end
end

