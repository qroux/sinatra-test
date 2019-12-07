# Sinatra Basic setup
require 'sinatra'
require 'sinatra/reloader'

# Authentication
require 'bcrypt'

# DB and ORM
require 'pg'
require 'sinatra/activerecord'
require 'faker'

# File imports
require_relative '../../db/database'
require_relative '../models/user.rb'
require_relative '../models/post.rb'
require_relative '../models/comment.rb'
require_relative '../models/vote.rb'
# helpers
# require_relative '../helpers/auth_helper.rb'

# running app
class ApplicationController < Sinatra::Base
  enable :inline_templates
  enable :sessions

  # configuration
  register Sinatra::ActiveRecordExtension

  configure :development do
    register Sinatra::Reloader
  end

  configure do
    set :views, 'app/views'
    set :public_dir, 'public'
  end

  # POSTS CONTROLLER
  # Log in/out + create user
  get '/test' do
    if current_user
      current_user.update(admin: true)

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
      @error = 'Username or password was incorrect'
      erb :sign_in
    end
  end

  get '/sign_up' do
    erb :sign_up, layout: :layout
  end

  post '/create_user' do
    user = User.create(username: params[:username],
                       password_hash: hash_password(params[:password]))

    if user.persisted?
      session.clear
      session[:user_id] = user.id
      redirect '/'
    else
      redirect 'sign_up'
    end
  end

  get '/sign_out' do
    session.clear
    redirect '/'
  end

  # index
  get '/' do
    @top_posts = Post.order(rating: :desc).first(2)
    @posts = Post.order(created_at: :desc)

    @user = current_user

    erb :home, layout: :layout
  end

  # create
  get '/posts/new' do
    erb :new, layout: :layout
  end

  post '/posts/create' do
    post = Post.create(title: params[:title],
                       content: params[:content],
                       photo: params[:url],
                       rating: 0,
                       user_id: current_user.id)

    redirect "/posts/#{post.id}"
  end

  # show
  get '/posts/:id' do
    set_post

    erb :show, layout: :layout
  end

  # Upvote/Downvote
  post '/posts/:id' do
    set_post
    @post.rating = 0 if @post.rating.nil?

    redirect to 'sign_in' unless current_user

    if voted.nil?
      if params[:sign] == '+'
        @post.rating += 1
      else
        @post.rating.positive? ? @post.rating -= 1 : @post.rating = 0
      end
      @post.save
      Vote.create(user_id: current_user.id, post_id: @post.id)
    end

    redirect to "/posts/#{@post.id}"
  end

  # import
  get '/import' do
    i = 0
    user = current_user.id

    DB.each do |post|
      Post.create(title: post[:title],
                  user_id: user,
                  content: post[:content],
                  photo: post[:photo],
                  rating: post[:rating] ||= 0)

      COMMENTS[i].each do |comment|
        Comment.create(post_id: Post.last.id, content: comment)
      end

      i += 1
    end

    redirect to '/'
  end

  # flush database
  get '/clear' do
    Post.destroy_all
    Comment.destroy_all

    redirect to '/'
  end

  # generate new random post
  get '/generate' do
    Post.create(title: Faker::Marketing.buzzwords,
                user_id: current_user.id,
                photo: "https://picsum.photos/id/#{rand(1000)}/600/600",
                rating: 0,
                content: Faker::Lorem.paragraph(sentence_count: 3,
                                                supplemental: true,
                                                random_sentences_to_add: 4))

    redirect to '/'
  end

  # COMMENTS CONTROLLER
  # Create
  post '/comments/create' do
    Comment.create(post_id: params[:post], content: params[:comment])

    redirect to "/posts/#{params[:post]}"
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def voted
    if current_user
      @vote = Vote.find_by(user_id: current_user.id, post_id: @post.id)
    else
      nil
    end
  end

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
      else
        nil
      end
    end
  end
end
