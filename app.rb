require 'dotenv'
require 'sinatra'
require 'shopify_api'
require 'httparty'

class GoodieBasket < Sinatra::Base

	def init
		Dotenv.load
		@api_key = ENV['api_key']
		@api_secret = ENV['api_secret']
		@app_url = ""
		@tokens = {}
	end

	get '/goodiebasket/install' do
		shop = 
		scopes = "read_products,write_products,read_orders"
		install_url = "https://{shop}.myshopify.com/admin/oauth/authorize?client_id={@api_key}&scope={scopes}&redirect_uri={@app_url}&state={nonce}"
	end

end