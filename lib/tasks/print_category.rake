namespace :print_category do

  task start: :environment do
    print_category(Category.first, 0)
  end

  def print_category(category, n)
    space = if n == 0
              ''
            elsif n == 1
              '  '
            elsif n == 2
              '    '
            elsif n == 3
              '      '
            elsif n == 4
              '        '
            elsif n == 5
              '          '
            end
    p "#{space}#{category.name} (#{category.amount})"
    m = n + 1 if category.subordinates.present?
    category.subordinates.each do |subordinate|
      print_category(subordinate, m)
    end
  end

end
