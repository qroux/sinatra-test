require 'sinatra/reloader'

# Authentication logic
class UsersController < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  configure do
    set :views, 'app/views'
    set :public_dir, 'public'
  end

  # Toggle admin privilege to curent_user
  get '/admin' do
    if current_user
      current_user.update(admin: !current_user.admin)

      redirect '/'
    else
      redirect '/sign_in'
    end
  end

  get '/sign_in' do
    if current_user
      redirect '/'
    else
      erb :sign_in, layout: :layout
    end
  end

  post '/sign_in' do
    user = User.find { |u| u.username == params[:username] }
    if user && test_password(params[:password], user.password_hash)
      session.clear
      session[:user_id] = user.id
      redirect back
    else
      @error = 'Identifiant ou mot de passe incorrect'
      erb :sign_in
    end
  end

  # new
  get '/sign_up' do
    erb :sign_up, layout: :layout
  end

  # create
  post '/create_user' do
    user = User.create(username: params[:username],
                       password_hash: hash_password(params[:password]))

    if user.persisted?
      session.clear
      session[:user_id] = user.id
      redirect '/'
    else
      @error = 'erreur à la création'
      erb :sign_up, layout: :layout
    end
  end

  get '/sign_out' do
    session.clear
    redirect '/'
  end

  private

  # Authentication
  def hash_password(password)
    BCrypt::Password.create(password).to_s
  end

  def test_password(password, hash)
    BCrypt::Password.new(hash) == password
  end

  # helpers
  helpers do
    def current_user
      if session[:user_id]
        User.find { |u| u.id == session[:user_id] }
      end
    end
  end
end
