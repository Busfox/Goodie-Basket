require 'dotenv'
require 'sinatra'
require 'shopify_api'
require 'httparty'

class GoodieBasket < Sinatra::Base

	def initialize
		Dotenv.load
		@key = ENV['API_KEY']
		@secret = ENV['API_SECRET']
		@app_url = "70144427.ngrok.io"
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

		query = params.reject{|k,_| k == 'hmac'}
		message = Rack::Utils.build_query(query)
		digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @secret, message)

		puts "digest: #{digest}"

		if not hmac == digest
			return [401, "Authorization failed!"]
		elsif hmac == digest
			return ["Authorization successful!"]
		end

		response = HTTParty.post('https://#{shop}.myshopify.com/admin/oauth/access_token',
			{ client_id: @key, client_secret: @secret, code: code })

		puts response

	end

	helpers do
		def verify_webhook(data, hmac)
	    digest  = OpenSSL::Digest::Digest.new('sha256')
	    digest = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), @secret, data)).strip
	    digest == hmac
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