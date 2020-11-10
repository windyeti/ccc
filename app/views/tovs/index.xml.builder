xml.instruct!
xml.yml_catalog do
	xml.shop do
		xml.categories do
			xml.category('Главная',"id" => '1')
		end	
		xml.offers do
		
		  @tov_all.each do |product|
			  if product.oldprice !=nil
				if product.oldprice.to_f > 0 
					a = "true"
				else
					a = "false"
				end 
				xml.offer("available" => "#{a}", "id" => product.fid) do
					xml.sku product.sku
					xml.name product.title
					xml.description do 
						xml.cdata! product.desc
					end
					xml.quantity product.oldprice
					xml.price product.price
					xml.picture URI.encode(product.pict)
					xml.categoryId "1"
					xml.vendor product.p1
					xml.param( product.p2, 'name'=>'Модель')
					xml.param(product.p3, 'name'=>'Вес')
					xml.param(product.p4, 'name'=>'Материал')
					xml.param(product.mtitle, 'name'=>'Проба')
					xml.param(product.mdesc, 'name'=>'Страна производитель')
					xml.param( product.mkeyw, 'name'=>'Объем')
					xml.param(product.cat1, 'name'=>'Вставка')			
				end
				
				end
		#       xml.comments do
		#         post.comments.each do |comment|
		#           xml.comment do
		#             xml.body comment.body
		#           end
		#         end
		#       end
		  end
		end
	end
end