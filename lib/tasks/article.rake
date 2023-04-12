namespace :article do

  task start: :environment do
    # category_url = "https://vst-msk.ru/portfolio"
    #
    # (1..9).each do |page|
    #   new_category_url = page == 1 ? category_url : "#{category_url}/?PAGEN_1=#{page}"
    #   doc = get_doc(new_category_url)
    #   doc_articles = doc.css(".content_wrapper_block .items .item")
    #   pp doc_anonces = get_data_anonce(doc_articles)
    #   create_article(doc_anonces)
    # end
    run_api_create_article
  end

  task csv: :environment do
    CSV.open("#{Rails.public_path}/redir_news.csv", "a+") do |csv|
      Article.all.each do |article|
        article_url = article.article_url
        insales_link = "https://myshop-bvw692.myinsales.ru#{article.insales_link}"
        csv << [article_url, insales_link]
      end
    end
  end

  task change_src: :environment do
    Article.all.each do |article|
      content = article.content
      new_content = get_change(content)
      article.update(content: new_content)
    end
  end

  def get_data_anonce(doc_anonces)
    doc_anonces.map do |doc_anonce|

      title = doc_anonce.at(".title").text.strip
      anonce_data = doc_anonce.at(".period-block").text.strip
      anonce_image = "https://vst-msk.ru" + doc_anonce.at(".image span")['data-src'] rescue nil
      anonce_text = doc_anonce.at(".section").inner_html rescue nil

      article_url = "https://vst-msk.ru" + doc_anonce.at(".title a")['href']

      {
        title: title,
        anonce_data: anonce_data,
        anonce_image: anonce_image,
        anonce_text: anonce_text,
        article_url: article_url
      }
    end
  end

  def create_article(doc_anonces)
    doc_anonces.each do |doc_anonce|
      begin
        p '==========='
        doc = get_doc(doc_anonce[:article_url])
        p '+++++++++++'
      rescue
        File.open("#{Rails.public_path}/err_blog.txt", "a+") do |f|
          f.write "#{doc_anonce}\n"
        end
      end

      if doc.present?
        doc_content = doc.at(".ordered-block .content-text")
        content = get_desc(doc_content)
        mtitle = doc.at("title").text.strip
        mdesc =  doc.at('meta[name="description"]')['content'] rescue nil
        mkeywords = doc.at('meta[name="keywords"]')['content'] rescue nil

        title = doc_anonce[:title]
        if Article.find_by(title: doc_anonce[:title]).present?
          count = 1
          loop do
            title = "#{title} #{count}"
            break unless Article.find_by(title: title).present?
            count += 1
          end
        end

        product_link = nil
        # product_link = get_insales_id_product_link(doc)

        pp data = {
          title: title,
          anonce_image: doc_anonce[:anonce_image],
          anonce_text: doc_anonce[:anonce_text],
          anonce_data: doc_anonce[:anonce_data],
          article_url: doc_anonce[:article_url],
          content: content,
          mtitle: mtitle,
          mdesc: mdesc,
          mkeywords: mkeywords,
          # product_link: product_link
        }
      else
        pp data = {
          title: title,
          anonce_image: doc_anonce[:anonce_image],
          anonce_text: doc_anonce[:anonce_text],
          anonce_data: doc_anonce[:anonce_data],
        }
      end
      Article.create(data)
    end
  end

  def run_api_create_article
    Article.all.order("id DESC").each do |blog|
      data = {
        title: blog.title,
        anonce_image: blog.anonce_image,
        anonce_text: blog.anonce_text,
        anonce_data: blog.anonce_data,
        content: blog.content,
        mtitle: blog.mtitle,
        mdesc: blog.mdesc,
        mkeywords: blog.mkeywords,
        # product_link: blog.product_link.present? ? blog.product_link.split(" ").map {|id| id.to_i} : nil
      }
      p response = api_article_create(data)
      if response["image.image"].present?
        p "ПЫТАЕМСЯ ЕЩЕ РАЗ СОЗДАТЬ"
        response = api_article_create(data)
      end
      p permalink = response["permalink"]
      blog.update(insales_link: "#{Rails.application.credentials[:shop][:domain]}/blogs/blog/#{permalink}")
    end
  end

  def api_article_create(data)
    sleep 1

    api_key = Rails.application.credentials[:shop][:api_key]
    password = Rails.application.credentials[:shop][:password]
    domain = Rails.application.credentials[:shop][:domain]

    blog_id = 2954310

    notice = (data[:anonce_data].present? ? data[:anonce_data] : '') + " " + (data[:anonce_text].present? ? data[:anonce_text] : "")
    data = 	{
      "article": {
        "title": data[:title],
        "content": data[:content],
        "notice": notice,
        "published_at": Time.now + 600, # 21.02.2022 00:00
        "author": "Admin",
        # "permalink": "first_article",
        "html_title": data[:mtitle],
        "meta_keywords": data[:mkeywords],
        "meta_description": data[:mdesc],
        "image_attributes": {
          "src": data[:anonce_image]
        },
        # "related_products": data[:product_link]
        # "all_tags": data[:tags],
      }
    }
    uri = "http://#{api_key}:#{password}@#{domain}/admin/blogs/#{blog_id}/articles.json"

    RestClient.post( uri, data.to_json, {:content_type => 'application/json', accept: :json}) do |response, request, result, &block|
      case response.code
      when 201
        puts 'code 201 - ok'
        body = JSON.parse(response.body)
        body
      when 422
        p 'code 422'
        p response.body
      else
        response.return!(&block)
      end
    end
  end


  task create_article_again: :environment do
    artilies = Article.where(insales_link: nil)
    artilies.each do |article|
      # pp category
      article = {
        "article": article
      }
      api_article_create(article)
    end
    p "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    p "XXXX  НЕ СОЗДАЛОСЬ СТАТЕЙ #{Article.where(insales_link: nil).count}  XXXX"
    p "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  end

  def get_insales_id_product_link(doc)
    @rows = CSV.read("#{Rails.public_path}/shop.csv", headers: true)
    # p links = doc.css(".related-art-product .product-thumb .product-thumb__name-container > a").map {|a| a["href"]}
    # selected_row = []
    # links.each do |href|
    #   @rows.each {|row| selected_row << row["ID товара"] if row["Параметр: OLDLINK"] == href}
    # end
    # p selected_row

    product_link_from_page = doc.css(".related-art-product .product-thumb .product-thumb__name-container > a")
                               .map {|a| a["href"].split("/").last}
                               .map do |permalink|
      @rows.find {|row| row["Параметр: OLDLINK"].split("/").last == permalink}
    end
                               .map {|row| row["ID товара"] }
    product_link_from_page.present? ? product_link_from_page.uniq.join(" ") : nil
  end


  def api_get_list_articles
    sleep 1

    api_key = Rails.application.credentials[:shop][:api_key]
    password = Rails.application.credentials[:shop][:password]
    domain = Rails.application.credentials[:shop][:domain]

    blog_id = 2954310

    uri = "http://#{api_key}:#{password}@#{domain}/admin/blogs/#{blog_id}/articles.json"

    RestClient.get( uri, {:content_type => 'application/json', accept: :json}) do |response, request, result, &block|
      case response.code
      when 200
        puts 'code 201 - ok'
        pp JSON.parse(response.body)
      when 422
        p 'code 422'
        p response.body
      else
        response.return!(&block)
      end
    end
  end
end
