class WeiboController < ApplicationController
  before_filter :login_required

  def index
    @new_client = Weibo2::Client.new

    unless current_user.weibo_auth.nil?
      @client = current_user.get_weibo_client
      if @client.is_authorized?
        response = @client.account.get_uid
        @weibo_user = @client.users.show(response.parsed).parsed
      end
    end

  end

  def callback
    code = params[:code]
    client = Weibo2::Client.from_code(code)

    if client.is_authorized?
      current_user.set_new_weibo_auth(code, client.token.token, client.token.expires_in)
    end

    redirect_to "/weibo"
  end

  # 发送微博
  def create
    client = current_user.get_weibo_client
    client.statuses.update(params[:content])

    redirect_to :back
  end

  # 根据 weibo api 把数据采集到本地
  def stats
    unless params[:screen_name].blank?

      screen_name = params[:screen_name]
      count = params[:count].blank?? 0: params[:count].to_i

      # 先根据 api 获取微博列表
      weibo_statuses = WeiboStatus.get_weibo_statuses(current_user, screen_name, count)

      # 存到数据库
      WeiboStatus.store_weibo_statuses(weibo_statuses)

      # 统计查询
      @weibo_user = WeiboUser.find_by_screen_name(screen_name)

    end
  end
  # end of stats

end
