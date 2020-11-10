namespace :parsing do
  task create_structure: :environment do
    url_source = "#{Rails.application.credentials[:shop][:catalog]}"
    selector_top_level = '#column-left .list-group .cat-active > a'
    # selector_top_level = '.accordeon_subcat.drop-right > li > a'
    selector_other_level = '.category-list li a'

    create_structure(
      {
        name: 'Asselina',
        link: url_source,
        category_path: 'Каталог/Asselina'
      },
      selector_top_level,
      selector_other_level,
      true
    )
  end
end
