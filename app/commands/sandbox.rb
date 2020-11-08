require './app/foundation.rb'

require 'pp'

def categories
  category_groups = ynab_api.categories.get_categories(MAIN_BUDGET_ID).data.category_groups
  output = {}
  category_groups.each do |category_group|
    key = "#{category_group.name} #{category_group.id}"
    value = category_group.categories.map { |c| "#{c.name} #{c.id}" }
    output[key] = value
  end

  output
end

binding.pry
