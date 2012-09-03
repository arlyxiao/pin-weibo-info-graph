class BilateralFriendship < ActiveRecord::Base
  belongs_to :weibo_user, 
             :class_name => 'WeiboUser', 
             :foreign_key => :weibo_user_id


  belongs_to :other_weibo_user, 
             :class_name => 'WeiboUser', 
             :foreign_key => :other_weibo_user_id


  validates :weibo_user_id, :other_weibo_user_id,  :presence => true
  validates :weibo_user_id, :uniqueness => {:scope => :other_weibo_user_id}

end
