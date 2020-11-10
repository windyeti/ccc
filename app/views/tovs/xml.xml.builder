xml.instruct!
xml.yml_catalog( :date => "#{Time.now.in_time_zone.strftime("%Y-%m-%d %H:%M")}") do
	xml.shop do
		xml.currencies do
		xml.currency(:id => "RUR", :rate => "1.0")
		end
# 		xml.categories do
# 		xml.category("Сантехника", :id => "1")
# 		xml.category("Комплектующие для сантехники", :id => "19", :parentId => "1")
# 		end
		xml.offers do
		
		  @tovs.each do |tov|
			  
				xml.offer("available" => "true", "id" => tov.id.to_s) do
					title = tov.title.gsub('&','&amp;')
					sku = tov.sku
					desc = tov.desc
					picts = tov.pict
					price  = tov.price
					params = tov.p2
					
					xml.name title
					xml.vendorCode sku
					xml.price "#{price}"
					xml.currencyId "RUR"
					xml.description "<![CDATA["+"#{desc}"+"]]>"
# 					xml.categoryId "19"
					picts.split(' ').each do |pict|
						if pict != "https://www.perfekto.ru/bitrix/templates/perfekto/img/icon-video-thumbs-slider.png"
						xml.picture pict
						end
					end
					params.split('; ,').each do |par|
						key = par.split('-')[0].strip
						if key == "Код базы"
						value = par.split('-')[1].strip+"-"+par.split('-')[2].strip || '' if par.split('-')[2] != nil
						else
						value = par.split('-')[1].gsub(';','').gsub('&','&amp;').strip
						end
						xml.param("#{value}", :name => "#{key}")
					end
				end
				
		  end
		end
	end
end
