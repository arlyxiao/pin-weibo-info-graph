class WeiboCommentsController < ApplicationController 

  def index
    unless params[:screen_name].nil?
      weibo_user = WeiboUser.find_by_screen_name(params[:screen_name])
      begin
        comments = weibo_user.get_all_comments(current_user)

        WeiboComment.save_comments(comments)

        @comments = WeiboComment.all
      rescue
        p 'user not in database'
      end
    end
  end

  # 根据某条微博id, 显示相关的所有评论
  def show
    @weibo_status = WeiboStatus.find_by_weibo_status_id(params[:id])
    @weibo_user = @weibo_status.weibo_user
    @weibo_comments = WeiboComment.find_all_by_weibo_status_id(params[:id])
  end

  # 重新更新某条微博对应的所有评论
  def refresh
    WeiboComment.update_by_weibo_status_id(current_user, params[:weibo_status_id])
    redirect_to :back
  end


  # 当前登录用户发出的评论列表
  def by_me
    # 把我所有发出的评论从数据表拿出来显示在view上
    @my_comments = current_user.weibo_auth.weibo_comments
  end

  def by_me_submit
    # 先根据 api 把最新评论存到数据库
    # 根据 api 从微博采集我的评论
    begin
      comments = current_user.weibo_auth.get_my_comments_by_count(params[:count].to_i)

      # 评论保存到数据库
      WeiboComment.save_comments(comments)
    rescue Exception=> ex
      p ex.message
      puts ex.backtrace*"\n"
      p 'weibo error'
    end
    redirect_to "/weibo_comments/by_me"
  end


  # 按星期分组，统计我发出的评论与其它用户的互动
  def stats3
    # 当前登录用户发出的评论按星期分组
    @week_comments = current_user.weibo_auth.group_comments_by_week

    # 当前登录用户转发的微博
    @retweeted_statuses = current_user.weibo_auth.weibo_user.retweeted_statuses

    # 当前登录用户转发的微博按星期分组
    @week_retweeted_statuses = current_user.weibo_auth.weibo_user.group_statuses_by_week

    p @week_retweeted_statuses
  end

end
