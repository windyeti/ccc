namespace :parsing do
  task create_structure: :environment do
    url_source = "#{Rails.application.credentials[:shop][:old_domain]}"
    selector_top_level = '.my_menu .ty-menu__item:not(.visible-phone) .ty-menu__item-link'
    selector_other_level = '.ty-mainbox-body .ty-subcategories__item a'

    create_structure(
      {
        link: url_source,
        category_path: 'Каталог'
      },
      selector_top_level,
      selector_other_level,
      true
    )
  end
end
