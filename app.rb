# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'

require_relative './db/database.rb'

get '/' do
  title_array = []

  DB.each do |element|
    title_array << element[:title]
  end

  erb :home, layout: :layout, locals: { frontVariable: title_array }
end

# # simple class test
# class HiSinatra < Sinatra::Base
#   get '/' do
#     'Hello world from class'
#   end

#   get '/posts' do
#     titleArray = []

#     DB.each do |element|
#       titleArray << element[:title]
#     end

#     "titleArray = #{titleArray}"
#     # "element: #{DB[0][:title]}"
#     # "element: #{DB.length}"


#     # myIndex = 0

#     # mdb.each do |element|
#     #   "nouveau post: #{myIndex} + #{element}"
#     # end
#   end
# end
