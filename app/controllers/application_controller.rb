require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'sinatra/activerecord'
require 'faker'

require_relative '../../db/database'
require_relative '../models/post.rb'
require_relative '../models/comment.rb'

# running app
class ApplicationController < Sinatra::Base
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
  # index
  get '/' do
    @top_posts = Post.order(rating: :desc).first(2)
    @posts = Post.order(created_at: :desc)

    erb :home, layout: :layout
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

    if params[:sign] == '+'
      @post.rating += 1
    else
      @post.rating.positive? ? @post.rating -= 1 : @post.rating = 0
    end

    @post.save
    redirect to "/posts/#{@post.id}"
  end

  # import
  get '/import' do
    i = 0

    DB.each do |post|
      Post.create(title: post[:title],
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
end
