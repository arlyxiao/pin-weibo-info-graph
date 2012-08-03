class UserWeiboAuth < ActiveRecord::Base
  belongs_to :user, :class_name => 'User', :foreign_key => 'user_id'

  has_many :weibo_comments, 
           :class_name => 'WeiboComment', :order => 'created_at',
           :foreign_key => :weibo_user_id, :primary_key => :weibo_user_id

  def weibo_client
    Weibo2::Client.from_hash(:access_token => self.token, :expires_in => self.expires_in)
  end

  has_one :weibo_user, :class_name => 'WeiboUser', 
          :foreign_key => :weibo_user_id, :primary_key => :weibo_user_id
  def get_my_comments_by_count(count)
    client = self.weibo_client

    current_page = 1
    if count <= 20
      response = client.comments.by_me(:page => current_page, :count => count).parsed
      comments = response['comments']
    else
      comments = []
      while true do
        response = client.comments.by_me(:page => current_page, :count => 20).parsed
        if comments.count + response['comments'].count < count
          comments = comments + response['comments']
          current_page += 1
        else
          index = count - comments.count
          comments += response['comments'][0...index]
          break
        end
      end
    end

    comments
  end

  def group_comments_by_week
    week_comments = []
    comments = self.weibo_comments

    start_date = Date.parse(comments[0].created_at.to_s)
    end_date = Date.parse(comments[comments.length - 1].created_at.to_s)
    
    first_week_days = 7 - comments[0].created_at.wday
    end_week_date = start_date + first_week_days

    if end_week_date >= end_date
      week_comments << comments
    else
      temp_comments = []
      comments.each do |comment|
        if comment.created_at <= end_week_date
          temp_comments << comment
        end
      end

      week_comments << temp_comments
      week_comments = self.divide_week_comments(week_comments, comments)
    end

    week_comments
  end

  def divide_week_comments(week_comments, comments)
    last_week_comments = week_comments[week_comments.length - 1]
    end_week_date = Date.parse(last_week_comments[last_week_comments.length - 1].created_at.to_s) + 7
    end_date = Date.parse(comments[comments.length - 1].created_at.to_s)


    temp_comments = []
    last_week_date = Date.parse(last_week_comments[last_week_comments.length - 1].created_at.to_s)


    if end_week_date < end_date
      
      comments.each do |comment|
        current_date = Date.parse(comment.created_at.to_s)
        if current_date > last_week_date && current_date <= end_week_date
          temp_comments << comment
        end
      end
      week_comments << temp_comments
      self.divide_week_comments(week_comments, comments)
    else
      end_week_date = last_week_date + 6
      comments.each do |comment|
        current_date = Date.parse(comment.created_at.to_s)
        if current_date > last_week_date && current_date <= end_week_date
          temp_comments << comment
        end
      end
      week_comments << temp_comments
      return week_comments
      
    end
  end


  # --- 给其他类扩展的方法
  module UserMethods
    def self.included(base)
      base.has_one :weibo_auth, :class_name => 'UserWeiboAuth', :foreign_key => :user_id

      base.send(:include, InstanceMethods)
    end
    
    module InstanceMethods
      def has_weibo_auth?
        !self.weibo_auth.blank?
      end

      # begin set_new_weibo_auth
      def set_new_weibo_auth(auth_code, client)
        # 如果过期重新设置的话，先删除，后面再创建新的
        if has_weibo_auth?
          self.weibo_auth.destroy
        end

        response = client.account.get_uid.parsed
        user = client.users.show(response).parsed

        UserWeiboAuth.create(
          :user => self, 
          :auth_code => auth_code, 
          :token => client.token.token, 
          :expires_in => client.token.expires_in,
          :weibo_user_id => response['uid'],
          :screen_name => user['screen_name'],
          :avatar => user['avatar_large']
        )
      end
      # end set_new_weibo_auth

      # begin get_weibo_client
      def get_weibo_client
        self.weibo_auth.weibo_client
      end
      # end get_weibo_client

    end
  end
  # end UserMethods

end
