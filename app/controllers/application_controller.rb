# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'sinatra/activerecord'

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
    @posts = Post.order(rating: :desc)

    erb :home, layout: :layout
  end

  # show
  get '/posts/:id' do
    @post = Post.find(params[:id])

    erb :show, layout: :layout
  end

  # import
  get '/import' do
    i = 0

    DB.each do |post|
      Post.create(title: post[:title],
                  content: post[:content],
                  photo: post[:photo],
                  rating: post[:rating])

      COMMENTS[i].each do |comment|
        Comment.create(post_id: Post.last.id, content: comment)
      end

      i += 1
    end

    redirect to '/'
  end

  get '/clear' do
    Post.destroy_all
    Comment.destroy_all

    redirect to '/'
  end
end
