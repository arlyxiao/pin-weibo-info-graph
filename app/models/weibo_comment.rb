class WeiboComment < ActiveRecord::Base
  belongs_to :auth_user, 
             :class_name => 'UserWeiboAuth', 
             :foreign_key => :weibo_user_id, :primary_key => :weibo_user_id

  belongs_to :weibo_status, 
             :class_name => 'WeiboStatus', 
             :foreign_key => :weibo_status_id, :primary_key => :weibo_status_id
  
  validates_uniqueness_of :weibo_comment_id


  def self.update_by_weibo_status_id(client_user, weibo_status_id)
    if weibo_status_id.nil?
      return
    end

    client = client_user.get_weibo_client
    response = client.comments.show(weibo_status_id).parsed
    comments = response['comments']

    unless comments.nil?
      WeiboComment.destroy_all(:weibo_status_id => weibo_status_id)
      save_comments(comments)
    end

  end
  # end of update_by_weibo_status_id

  def self.save_comments(comments)
    unless comments.nil?
      comments.each do |comment|

        WeiboComment.create(
          :weibo_comment_id => comment['idstr'],
          :text => comment['text'],
          :weibo_user_id => comment['user']['idstr'],
          :weibo_status_id => comment['status']['idstr']
        )

        WeiboStatus.save_new(comment['status'])
      end
    end
  end
  # end of save_comments


end
