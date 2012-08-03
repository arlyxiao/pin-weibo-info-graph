class WeiboUser < ActiveRecord::Base
  has_many :weibo_statuses, 
           :class_name => 'WeiboStatus', :order => 'created_at',
           :foreign_key => :weibo_user_id, :primary_key => :weibo_user_id


  has_many :retweeted_statuses, 
           :class_name => 'WeiboStatus', :order => 'created_at',
           :foreign_key => :weibo_user_id, :primary_key => :weibo_user_id,
           :conditions => ["retweeted_status_id != ''"]


  validates_uniqueness_of :weibo_user_id

  STOP_WORDS = begin
    file = File.new File.expand_path(Rails.root.to_s + '/lib/stopwords.txt')
    file.read.split("\r\n") - ['']
  end

  def word_stats
    words = Hash.new(0)
    statuses = self.weibo_statuses

    statuses.each do |status|

      algor = RMMSeg::Algorithm.new(_prepate_text(status.text))
    
      loop do
        tok = algor.next_token
        break if tok.nil?

        word = tok.text
        if !STOP_WORDS.include?(word) && word.split(//u).length > 1
          words[word] = words[word] + 1
        end
      end
    end

    words
  end

  def _prepate_text(status_text)
    s1 = status_text.gsub /@\S+/, ''
    # s2 = s1.gsub /http:\/\/t.cn\/\S+/, ''
    s2 = s1.gsub /http:\/\/\S+/, ''
  end

  # -----------
  
  def get_all_comments(client_user)
    client = client_user.get_weibo_client

    statuses = self.weibo_statuses
    if !statuses.nil? && statuses.any?
      comments = []
      statuses.each do |status|
        response = client.comments.show(status.weibo_status_id).parsed
        comments = comments + response['comments']
      end
    end

    comments
  end
  # end of get_all_comments



  def group_statuses_by_week
    week_statuses = []
    statuses = self.retweeted_statuses

    start_date = Date.parse(statuses[0].created_at.to_s)
    end_date = Date.parse(statuses[statuses.length - 1].created_at.to_s)
    
    first_week_days = 7 - statuses[0].created_at.wday
    end_week_date = start_date + first_week_days

    if end_week_date >= end_date
      week_statuses << statuses
    else
      temp_statuses = []
      statuses.each do |status|
        if status.created_at <= end_week_date
          temp_statuses << status
        end
      end

      week_statuses << temp_statuses
      week_statuses = self.divide_week_statuses(week_statuses, statuses)
    end

    week_statuses
    
  end

  def divide_week_statuses(week_statuses, statuses)
    last_week_statuses = week_statuses[week_statuses.length - 1]
    end_week_date = Date.parse(last_week_statuses[last_week_statuses.length - 1].created_at.to_s) + 7
    end_date = Date.parse(statuses[statuses.length - 1].created_at.to_s)


    temp_statuses = []
    last_week_date = Date.parse(last_week_statuses[last_week_statuses.length - 1].created_at.to_s)


    if end_week_date < end_date
      
      statuses.each do |status|
        current_date = Date.parse(status.created_at.to_s)
        if current_date > last_week_date && current_date <= end_week_date
          temp_statuses << status
        end
      end
      week_statuses << temp_statuses
      self.divide_week_statuses(week_statuses, statuses)
    else
      end_week_date = last_week_date + 6
      statuses.each do |status|
        current_date = Date.parse(status.created_at.to_s)
        if current_date > last_week_date && current_date <= end_week_date
          temp_statuses << status
        end
      end
      week_statuses << temp_statuses
      return week_statuses
      
    end
  end



 
end
