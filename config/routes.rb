PinWorkResultsShow::Application.routes.draw do
  # -- 用户登录认证相关 --
  root :to=>"index#index"
  get  '/login'  => 'sessions#new'
  post '/login'  => 'sessions#create'
  get  '/logout' => 'sessions#destroy'
  
  get  '/signup'        => 'signup#form'
  post '/signup_submit' => 'signup#form_submit'


  resources :weibo do
    collection do
      get :callback
      get :stats
    end
  end

  resources :weibo_users do
    member do
      get :word_stats
      get :refresh
    end
  end
  # end of weibo users

  
  # begin of weibo comments
  resources :weibo_comments do
    collection do
      # 我发出的评论
      get :by_me
      post :by_me_submit

      # 我收到的评论
      get :to_me
      post :to_me_submit
    end
  end

  put  '/weibo_comments/:weibo_status_id/refresh'        => 'weibo_comments#refresh'
  # end of weibo comments



  # begin of stats
  resources :weibo_stats do
    collection do
      # 统计分析：词汇使用趋势
      get :stats1

      # 统计分析: 评论转发趋势
      get :stats3

      # 统计分析：被评论趋势
      get :stats11

      # 互相关注度
      get :stats12
      post :stats12_submit
    end
  end
  # end of stats


end
