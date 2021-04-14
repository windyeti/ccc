	task insales_param: :environment do
		puts 'start'
		vparamHeader = []
		p = Tov.all.select(:p1)
		p.each do |p|
			if p.p1 != nil
				p.p1.split('---').each do |pa|
					vparamHeader << pa.split(':')[0].strip if pa != nil
				end
			end
		end
		values = vparamHeader.uniq
		values.each do |value|
			puts "параметр - "+"#{value}"
			url = "http://#{Rails.application.credentials[:shop][:api_key]}:#{Rails.application.credentials[:shop][:password]}@#{Rails.application.credentials[:shop][:domain]}/admin/properties.json"
				data = 	{
						"property":
							    {
								"title": "#{value}"
							    }
							}
				
				RestClient.post( url, data.to_json, {:content_type => 'application/json', accept: :json}) { |response, request, result, &block|
					puts response.code
								case response.code
								when 201
									sleep 0.2
									puts 'sleep 0.2-201 - сохранили'
# 									puts response
								when 422
									puts '422'
								else
									response.return!(&block)
								end
								}
		end
		puts 'finish'
	end
