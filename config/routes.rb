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
    end
  end
  # end of weibo users

  
  # begin of weibo comments
  resources :weibo_comments do
    collection do
      get :by_me
      post :by_me_submit
      get :stats3
    end
  end

  put  '/weibo_comments/:weibo_status_id/refresh'        => 'weibo_comments#refresh'
  # end of weibo comments


end
