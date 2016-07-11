require 'dotenv'
require 'sinatra'
require 'shopify_api'
require 'httparty'

class GoodieBasket < Sinatra::Base

	def initialize
		Dotenv.load
		@key = ENV['API_KEY']
		@secret = ENV['API_SECRET']
		@app_url = "29fc4405.ngrok.io"
		@tokens = {}
		super
	end

	get '/goodiebasket/install' do
		shop = params[:shop]
		scopes = "read_products,write_products,read_orders"

		install_url = "http://#{shop}/admin/oauth/authorize?client_id=#{@key}&scope=#{scopes}&redirect_uri=https://#{@app_url}/goodiebasket/auth"
		redirect install_url
	end

	get '/goodiebasket/auth' do
		shop = params[:shop]
		hmac = params[:hmac]
		code = params[:code]

		#do some auth type stuff here

	end

	helpers do
		def verify_webhook(data, hmac)
	    digest  = OpenSSL::Digest::Digest.new('sha256')
	    calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, @secret, data)).strip
	    calculated_hmac == hmac
	  end
	end

  
  post 'goodiebasket/webhook/order_create' do

		request.body.rewind
	 	data = request.body.read
	 	verified = verify_webhook(data, env["HTTP_X_SHOPIFY_HMAC_SHA256"])

	 	if verified 
	 		#good stuff
	 	else
	 		#bad stuff
	 	end

	 	data_json = JSON.parse request.body.read

	 	line_items = data_json['line_items']

	 	line_items.each do |line_item|
	 		variant_id = line_item['variant_id']
	 		variant = ShopifyAPI::Variant.find(variant_id)

	 		variant.metafields.each do |metafield|
	 			if metafield.key == 'goodie'
	 				items = metafield.split(',')
	 				items.each do |item|
	 					goodie_item = ShopifyAPI::Variant.find(item)
	 					goodie_item.inventory_quantity = goodie_item.inventory_quantity - 1
	 				end
	 			end
	 		end

	 	end

	 	return [200, "Webhook successful."]

	end

end

GoodieBasket.run!