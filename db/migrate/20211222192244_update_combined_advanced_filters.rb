class UpdateCombinedAdvancedFilters < ActiveRecord::Migration[6.1]
  FILTER_MAPPINGS = {
    'address-foreign': 'address',
    'address-usa': 'address',
    'first-name': 'name',
    'last-name': 'name',
    'middle-name': 'name',
    'telephone-number': 'telephone',
    'telephone-number-partial': 'telephone',
  }

  NEW_FILTER_OPTIONS = {
    address: {
      name: 'address',
      title: 'Address (Combination)',
      description: 'Monitorees with specified address',
      type: 'combination',
      fields: [
        { name: 'address-foreign', title: 'outside USA', type: 'search' },
        { name: 'address-usa', title: 'within USA', type: 'search' }
      ]
    },
    name: {
      name: 'name',
      title: 'Name (Combination)',
      description: 'Monitoree name',
      type: 'combination',
      fields: [
        { name: 'first-name', title: 'first', type: 'search' },
        { name: 'last-name', title: 'last', type: 'search' },
        { name: 'middle-name', title: 'middle', type: 'search' }
      ]
    },
    telephone: {
      name: 'telephone',
      title: 'Primary Contact Telephone Number (Text)',
      description: 'Monitorees with a primary contact telephone number',
      type: 'search',
      options: ['Exact Match', 'Contains']
    }
  }

  OLD_FILTER_OPTIONS = {
    'address-foreign': {
      name: 'address-foreign',
      title: 'Address (outside USA) (Text)',
      description: 'Monitoree Address 1, Town/City, Country, Address 2, Postal Code, Address 3 or State/Province (outside USA)',
      type: 'search'
    },
    'address-usa': {
      name: 'address-usa',
      title: 'Address (within USA) (Text)',
      description: 'Monitoree Address 1, Town/City, State, Address 2, Zip, or County within USA',
      type: 'search'
    },
    'first-name': {
      name: 'first-name',
      title: 'Name (First) (Text)',
      description: 'Monitoree first name',
      type: 'search'
    },
    'last-name': {
      name: 'last-name',
      title: 'Name (Last) (Text)',
      description: 'Monitoree last name',
      type: 'search'
    },
    'middle-name': {
      name: 'middle-name',
      title: 'Name (Middle) (Text)',
      description: 'Monitoree middle name',
      type: 'search'
    },
    'telephone-number': {
      name: 'telephone-number',
      title: 'Primary Contact Telephone Number (Exact Match) (Text)',
      description: 'Monitorees with a specified 10 digit primary contact telephone number',
      type: 'search'
    },
    'telephone-number-partial': {
      name: 'telephone-number-partial',
      title: 'Primary Contact Telephone Number (Contains) (Text)',
      description: 'Monitorees with a primary contact telephone number that contains specified digits',
      type: 'search'
    }
  }

  def up
    relevant_filters.each do |filter|
      contents = JSON.parse(filter[:contents])
      contents.each do |content|
        filter_name = content['filterOption']['name'].to_sym
        if %i[address-foreign address-usa first-name last-name middle-name].include?(filter_name)
          content['filterOption'] = NEW_FILTER_OPTIONS[FILTER_MAPPINGS[filter_name].to_sym]
          content['value'] = [{ name: filter_name, value: content['value']}]
        elsif %i[telephone-number telephone-number-partial].include?(filter_name)
          content['filterOption'] = NEW_FILTER_OPTIONS[FILTER_MAPPINGS[filter_name].to_sym]
          content['additionalFilterOption'] = filter_name == :'telephone-number-partial' ? 'Contains' : 'Exact Match'
        end
      end
      filter.update!(contents: contents.to_json)
    end
  end

  def down
    relevant_filters.each do |filter|
      contents = JSON.parse(filter[:contents])
      contents.each do |content|
        filter_name = content['filterOption']['name'].to_sym
        next if content['value'].empty?

        if %i[address name].include?(filter_name)
          next if content['value'].first['name'].blank?

          content['filterOption'] = OLD_FILTER_OPTIONS[content['value'].first['name'].to_sym]
          content['value'] = content['value'].first['value']
        elsif filter_name == :telephone
          content['filterOption'] = OLD_FILTER_OPTIONS[content['additionalFilterOption'] == 'Contains' ? :'telephone-number-partial' : :'telephone-number']
        end
      end
      filter.update!(contents: contents.to_json)
    end
  end

  def relevant_filters
    UserFilter.where('contents LIKE "%address-foreign%"').or(
      UserFilter.where('contents LIKE "%address-usa%"').or(
        UserFilter.where('contents LIKE "%first-name%"').or(
          UserFilter.where('contents LIKE "%last-name%"').or(
            UserFilter.where('contents LIKE "%middle-name%"').or(
              UserFilter.where('contents LIKE "%last-name%"').or(
                UserFilter.where('contents LIKE "%telephone%"')
              )
            )
          )
        )
      )
    )
  end
end
