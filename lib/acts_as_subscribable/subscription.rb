class Subscription < ActiveRecord::Base
  belongs_to :subscribable, :polymorphic => :true
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => [:subscribable_type, :subscribable_id]
end

