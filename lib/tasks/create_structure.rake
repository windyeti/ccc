namespace :parsing do
  task create_structure: :environment do
    url_source = "#{Rails.application.credentials[:shop][:old_domain]}"
    selector_top_level = '.t-menusub__content .t-menusub__list-item a'
    selector_other_level = '.ZXC'

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
