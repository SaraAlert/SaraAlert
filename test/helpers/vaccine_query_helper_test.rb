# frozen_string_literal: true

require 'test_case'

class VaccineQueryHelperTest < ActiveSupport::TestCase
  include VaccineQueryHelper

  def setup
    # Fake the vaccine config in the Vaccine class for testing with multiple groups
    custom_config = {
      'COVID-19' => {
        'name' => 'COVID-19',
        'vaccines' => [
          {
            'product_name' => 'Moderna COVID-19 Vaccine (non-US Spikevax)',
            'num_doses' => 2
          },
          {
            'product_name' => 'Pfizer-BioNTech COVID-19 Vaccine (COMIRNATY)',
            'num_doses' => 2
          },
          {
            'product_name' => 'Janssen (J&J) COVID-19 Vaccine',
            'num_doses' => 1
          }
        ]
      },
      'TestGroup' => {
        'name' => 'TestGroup',
        'vaccines' => [
          {
            'product_name' => 'TestVaccine',
            'num_doses' => 2
          }
        ]
      }
    }

    redefine_constant(Vaccine, 'VACCINE_STANDARDS', custom_config)
  end

  def teardown
    redefine_constant(Vaccine, 'VACCINE_STANDARDS', Rails.configuration.vaccine_standards.freeze)
  end

  # --- validate_query_helper --- #

  test 'validate_vaccines_query: validates sort direction' do
    patient = create(:patient)
    create(:vaccine, patient: patient)

    # INVALID SORT DIRECTION

    # Data is stringified as it would be in actual request
    params = {
      patient_id: patient.id.to_s,
      entries: '10',
      page: '0',
      search: '',
      order: 'id',
      direction: 'test' # invalid - should be 'asc' or 'desc'
    }
    controller_params = ActionController::Parameters.new(params.merge({ controller: 'vaccines', action: 'index' }))

    error = assert_raise(StandardError) { validate_vaccines_query(controller_params) }
    assert_equal("Unable to sort column in specified direction in request: '#{params[:direction]}'", error.message)

    # VALID SORT DIRECTIONS
    %w[asc desc].each do |sort_direction|
      params = {
        patient_id: patient.id.to_s,
        entries: '10',
        page: '0',
        search: '',
        order: 'id',
        direction: sort_direction
      }
      controller_params = ActionController::Parameters.new(params.merge({ controller: 'vaccines', action: 'index' }))

      data = validate_vaccines_query(controller_params)
      assert_equal(
        {
          patient_id: patient.id,
          search_text: '',
          sort_order: 'id',
          sort_direction: sort_direction,
          entries: 10,
          page: 0
        },
        data
      )
    end
  end

  test 'validate_vaccines_query: validates sort order' do
    patient = create(:patient)
    create(:vaccine, patient: patient)

    # INVALID SORT ORDER

    # Data is stringified as it would be in actual request
    params = {
      patient_id: patient.id.to_s,
      entries: '10',
      page: '0',
      search: '',
      order: 'test', # invalid - should be sortable column for vaccines
      direction: 'desc'
    }
    controller_params = ActionController::Parameters.new(params.merge({ controller: 'vaccines', action: 'index' }))

    error = assert_raise(StandardError) { validate_vaccines_query(controller_params) }
    assert_equal("Unable to sort by specified column in request: '#{params[:order]}'", error.message)

    # VALID SORT ORDERS
    %w[id group_name product_name administration_date dose_number notes].each do |sort_column|
      params = {
        patient_id: patient.id.to_s,
        entries: '10',
        page: '0',
        search: '',
        order: sort_column,
        direction: 'asc'
      }
      controller_params = ActionController::Parameters.new(params.merge({ controller: 'vaccines', action: 'index' }))

      data = validate_vaccines_query(controller_params)
      assert_equal(
        {
          patient_id: patient.id,
          search_text: '',
          sort_order: sort_column,
          sort_direction: 'asc',
          entries: 10,
          page: 0
        },
        data
      )
    end
  end

  test 'validate_vaccines_query: validates must have both or neither sort direction and sort order' do
    patient = create(:patient)
    create(:vaccine, patient: patient)

    # INVALID BECAUSE NO SORT DIRECTION SPECIFIED
    params = {
      patient_id: patient.id.to_s,
      entries: '10',
      page: '0',
      search: '',
      order: 'id',
      direction: ''
    }
    controller_params = ActionController::Parameters.new(params.merge({ controller: 'vaccines', action: 'index' }))

    error = assert_raise(StandardError) { validate_vaccines_query(controller_params) }
    assert_equal('Must have both a sort column and direction specified or neither specified. Requested column to sort: '\
      "'#{params[:order]}'', with specified direction: '#{params[:direction]}'", error.message)

    # INVALID BECAUSE NO SORT ORDER SPECIFIED
    params = {
      patient_id: patient.id.to_s,
      entries: '10',
      page: '0',
      search: '',
      order: '',
      direction: 'asc'
    }
    controller_params = ActionController::Parameters.new(params.merge({ controller: 'vaccines', action: 'index' }))

    error = assert_raise(StandardError) { validate_vaccines_query(controller_params) }
    assert_equal('Must have both a sort column and direction specified or neither specified. Requested column to sort: '\
      "'#{params[:order]}'', with specified direction: '#{params[:direction]}'", error.message)
  end

  test 'validate_vaccines_query: validates pagination data' do
    patient = create(:patient)
    create(:vaccine, patient: patient)

    # INVALID - NEGATIVE PAGE NUMBER
    params = {
      patient_id: patient.id.to_s,
      entries: '10',
      page: '-1',
      search: '',
      order: 'id',
      direction: 'asc'
    }
    controller_params = ActionController::Parameters.new(params.merge({ controller: 'vaccines', action: 'index' }))

    error = assert_raise(StandardError) { validate_vaccines_query(controller_params) }
    assert_equal("Invalid Query (page): #{params[:page]}", error.message)

    # INVALID - NEGATIVE ENTRIES
    params = {
      patient_id: patient.id.to_s,
      entries: '-1',
      page: '0',
      search: '',
      order: 'id',
      direction: 'asc'
    }
    controller_params = ActionController::Parameters.new(params.merge({ controller: 'vaccines', action: 'index' }))

    error = assert_raise(StandardError) { validate_vaccines_query(controller_params) }
    assert_equal("Invalid Query (entries): #{params[:entries]}", error.message)
  end

  test 'validate_vaccines_query: assumes default pagination values if not provided' do
    patient = create(:patient)
    create(:vaccine, patient: patient)

    # Don't provide page and entries values
    params = {
      patient_id: patient.id.to_s,
      search: '',
      order: 'id',
      direction: 'desc'
    }
    controller_params = ActionController::Parameters.new(params.merge({ controller: 'vaccines', action: 'index' }))

    data = validate_vaccines_query(controller_params)
    assert_equal(
      {
        patient_id: patient.id,
        search_text: '',
        sort_order: 'id',
        sort_direction: 'desc',
        entries: 10,
        page: 0
      },
      data
    )
  end

  # --- search --- #

  test 'search: supports search for ID' do
    patient = create(:patient)
    vaccine_1 = create(:vaccine, patient: patient)
    create(:vaccine, patient: patient)

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)

    searched_vaccines = search(vaccines, vaccine_1.id.to_s)

    assert_equal(1, searched_vaccines.size)
    assert_equal(vaccine_1.id, searched_vaccines.first.id)
  end

  test 'search: supports search for group_name' do
    patient = create(:patient)

    # Give two different group names (guaranteed to be two based on the setup mock)
    group_name_options = Vaccine.group_name_options
    vaccine_1 = create(:vaccine, patient: patient, group_name: group_name_options[0])
    create(:vaccine, patient: patient, group_name: group_name_options[1])

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)

    searched_vaccines = search(vaccines, vaccine_1.group_name)

    assert_equal(1, searched_vaccines.size)
    assert_equal(vaccine_1.group_name, searched_vaccines.first.group_name)
  end

  test 'search: supports search for product_name' do
    patient = create(:patient)

    # Give two different product names (guaranteed to be two based on the setup mock)
    group_name = Vaccine.group_name_options[0]
    product_name_options = Vaccine.product_name_options(group_name)
    create(:vaccine, patient: patient, group_name: group_name, product_name: product_name_options[0])
    vaccine_2 = create(:vaccine, patient: patient, group_name: group_name, product_name: product_name_options[1])

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)

    searched_vaccines = search(vaccines, vaccine_2.product_name)

    assert_equal(1, searched_vaccines.size)
    assert_equal(vaccine_2.product_name, searched_vaccines.first.product_name)
  end

  test 'search: does nothing if search field is blank' do
    patient = create(:patient)
    create(:vaccine, patient: patient)
    create(:vaccine, patient: patient)

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)

    searched_vaccines = search(vaccines, '')

    assert_equal(2, searched_vaccines.size)
  end

  # --- sort --- #

  test 'sort: supports sort by ID' do
    patient = create(:patient)
    vaccine_1 = create(:vaccine, patient: patient)
    vaccine_2 = create(:vaccine, patient: patient)

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)
    sort_column = 'id'

    # DESC
    sort_direction = 'desc'
    sorted_vaccines = sort(vaccines, sort_column, sort_direction)

    assert_equal(2, sorted_vaccines.size)
    assert_equal(vaccine_2.id, sorted_vaccines.first.id)
    assert_equal(vaccine_1.id, sorted_vaccines.second.id)

    # ASC
    sort_direction = 'asc'
    sorted_vaccines = sort(vaccines, sort_column, sort_direction)

    assert_equal(2, sorted_vaccines.size)
    assert_equal(vaccine_1.id, sorted_vaccines.first.id)
    assert_equal(vaccine_2.id, sorted_vaccines.second.id)
  end

  test 'sort: supports sort by group_name' do
    patient = create(:patient)

    # Give two different group names (guaranteed to be two based on the setup mock)
    group_name_options = Vaccine.group_name_options
    vaccine_1 = create(:vaccine, patient: patient, group_name: group_name_options[0])
    vaccine_2 = create(:vaccine, patient: patient, group_name: group_name_options[1])

    # Determine what the order should be
    smaller = vaccine_1[:group_name] <= vaccine_2[:group_name] ? vaccine_1 : vaccine_2
    larger = smaller.id == vaccine_1.id ? vaccine_2 : vaccine_1

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)
    sort_column = 'group_name'

    # DESC
    sort_direction = 'desc'
    sorted_vaccines = sort(vaccines, sort_column, sort_direction)

    assert_equal(2, sorted_vaccines.size)
    assert_equal(larger.id, sorted_vaccines.first.id)
    assert_equal(smaller.id, sorted_vaccines.second.id)

    # ASC
    sort_direction = 'asc'
    sorted_vaccines = sort(vaccines, sort_column, sort_direction)

    assert_equal(2, sorted_vaccines.size)
    assert_equal(smaller.id, sorted_vaccines.first.id)
    assert_equal(larger.id, sorted_vaccines.second.id)
  end

  test 'sort: supports sort by product_name' do
    patient = create(:patient)

    # Give two different product names (guaranteed to be two based on the setup mock)
    group_name = Vaccine.group_name_options[0]
    product_name_options = Vaccine.product_name_options(group_name)
    vaccine_1 = create(:vaccine, patient: patient, group_name: group_name, product_name: product_name_options[0])
    vaccine_2 = create(:vaccine, patient: patient, group_name: group_name, product_name: product_name_options[1])

    # Determine what the order should be
    smaller = vaccine_1[:product_name] <= vaccine_2[:product_name] ? vaccine_1 : vaccine_2
    larger = smaller.id == vaccine_1.id ? vaccine_2 : vaccine_1

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)
    sort_column = 'product_name'

    # DESC
    sort_direction = 'desc'
    sorted_vaccines = sort(vaccines, sort_column, sort_direction)

    assert_equal(2, sorted_vaccines.size)
    assert_equal(larger.id, sorted_vaccines.first.id)
    assert_equal(smaller.id, sorted_vaccines.second.id)

    # ASC
    sort_direction = 'asc'
    sorted_vaccines = sort(vaccines, sort_column, sort_direction)

    assert_equal(2, sorted_vaccines.size)
    assert_equal(smaller.id, sorted_vaccines.first.id)
    assert_equal(larger.id, sorted_vaccines.second.id)
  end

  test 'sort: supports sort by administration_date' do
    patient = create(:patient)
    vaccine_1 = create(:vaccine, patient: patient, administration_date: 1.day.ago)
    vaccine_2 = create(:vaccine, patient: patient, administration_date: 2.days.ago)
    vaccine_3 = create(:vaccine, patient: patient, administration_date: nil)

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)
    sort_column = 'administration_date'

    # DESC
    sort_direction = 'desc'
    sorted_vaccines = sort(vaccines, sort_column, sort_direction)

    assert_equal(3, sorted_vaccines.size)
    assert_equal(vaccine_1.id, sorted_vaccines.first.id)
    assert_equal(vaccine_2.id, sorted_vaccines.second.id)
    assert_equal(vaccine_3.id, sorted_vaccines.third.id)

    # ASC
    sort_direction = 'asc'
    sorted_vaccines = sort(vaccines, sort_column, sort_direction)

    assert_equal(3, sorted_vaccines.size)
    assert_equal(vaccine_2.id, sorted_vaccines.first.id)
    assert_equal(vaccine_1.id, sorted_vaccines.second.id)
    assert_equal(vaccine_3.id, sorted_vaccines.third.id)
  end

  test 'sort: supports sort by dose_number' do
    patient = create(:patient)
    vaccine_1 = create(:vaccine, patient: patient, dose_number: '1')
    vaccine_2 = create(:vaccine, patient: patient, dose_number: '2')
    vaccine_3 = create(:vaccine, patient: patient, dose_number: 'Unknown')
    vaccine_4 = create(:vaccine, patient: patient, dose_number: nil)
    vaccine_5 = create(:vaccine, patient: patient, dose_number: '')

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)
    sort_column = 'dose_number'

    # DESC
    sort_direction = 'desc'
    sorted_vaccines = sort(vaccines, sort_column, sort_direction)

    assert_equal(5, sorted_vaccines.size)
    assert_equal(vaccine_3.id, sorted_vaccines.first.id)
    assert_equal(vaccine_2.id, sorted_vaccines.second.id)
    assert_equal(vaccine_1.id, sorted_vaccines.third.id)
    assert_equal(vaccine_5.id, sorted_vaccines.fourth.id)
    assert_equal(vaccine_4.id, sorted_vaccines.fifth.id)

    # ASC
    sort_direction = 'asc'
    sorted_vaccines = sort(vaccines, sort_column, sort_direction)

    assert_equal(5, sorted_vaccines.size)
    assert_equal(vaccine_1.id, sorted_vaccines.first.id)
    assert_equal(vaccine_2.id, sorted_vaccines.second.id)
    assert_equal(vaccine_3.id, sorted_vaccines.third.id)
    assert_equal(vaccine_5.id, sorted_vaccines.fourth.id)
    assert_equal(vaccine_4.id, sorted_vaccines.fifth.id)
  end

  test 'sort: supports sort by notes' do
    patient = create(:patient)
    vaccine_1 = create(:vaccine, patient: patient, notes: 'This is a note.')
    vaccine_2 = create(:vaccine, patient: patient, notes: 'Hey what a cool note!')
    vaccine_3 = create(:vaccine, patient: patient, notes: nil)
    vaccine_4 = create(:vaccine, patient: patient, notes: '')

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)
    sort_column = 'notes'

    # DESC
    sort_direction = 'desc'
    sorted_vaccines = sort(vaccines, sort_column, sort_direction)

    assert_equal(4, sorted_vaccines.size)
    assert_equal(vaccine_1.id, sorted_vaccines.first.id)
    assert_equal(vaccine_2.id, sorted_vaccines.second.id)
    assert_equal(vaccine_4.id, sorted_vaccines.third.id)
    assert_equal(vaccine_3.id, sorted_vaccines.fourth.id)

    # ASC
    sort_direction = 'asc'
    sorted_vaccines = sort(vaccines, sort_column, sort_direction)

    assert_equal(4, sorted_vaccines.size)
    assert_equal(vaccine_2.id, sorted_vaccines.first.id)
    assert_equal(vaccine_4.id, sorted_vaccines.third.id)
    assert_equal(vaccine_3.id, sorted_vaccines.fourth.id)
  end

  test 'sort: sorts by creation date if no sort order or no sort direction is specified' do
    patient = create(:patient)
    vaccine_1 = create(:vaccine, patient: patient, created_at: 2.days.ago)
    vaccine_2 = create(:vaccine, patient: patient, created_at: 1.day.ago)

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)

    # NO SORT COLUMN/ORDER
    sort_direction = 'desc'
    sorted_vaccines = sort(vaccines, nil, sort_direction)

    assert_equal(2, sorted_vaccines.size)
    assert_equal(vaccine_2.id, sorted_vaccines.first.id)
    assert_equal(vaccine_1.id, sorted_vaccines.second.id)

    # NO SORT DIRECTION
    sort_column = 'notes'
    sorted_vaccines = sort(vaccines, sort_column, nil)

    assert_equal(2, sorted_vaccines.size)
    assert_equal(vaccine_2.id, sorted_vaccines.first.id)
    assert_equal(vaccine_1.id, sorted_vaccines.second.id)
  end

  # --- paginate --- #

  test 'paginate: does nothing if pagination data is not valid' do
    patient = create(:patient)
    create(:vaccine, patient: patient)
    create(:vaccine, patient: patient)

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)

    # 0 ENTRIES
    entries = 0
    page = 0

    paginated_vaccines = paginate(vaccines, entries, page)
    assert_equal(2, paginated_vaccines.size)
    # If paginated, will be able to access Paginator methods
    assert_not paginated_vaccines.respond_to?(:total_entries)

    # NEGATIVE ENTRIES
    entries = -1
    page = 0

    paginated_vaccines = paginate(vaccines, entries, page)
    assert_equal(2, paginated_vaccines.size)
    assert_not paginated_vaccines.respond_to?(:total_entries)

    # NIL ENTRIES
    entries = nil
    page = 0

    paginated_vaccines = paginate(vaccines, entries, page)
    assert_equal(2, paginated_vaccines.size)
    assert_not paginated_vaccines.respond_to?(:total_entries)

    # NEGATIVE PAGE
    entries = 10
    page = -1

    paginated_vaccines = paginate(vaccines, entries, page)
    assert_equal(2, paginated_vaccines.size)
    assert_not paginated_vaccines.respond_to?(:total_entries)

    # NIL PAGE
    entries = 10
    page = nil

    paginated_vaccines = paginate(vaccines, entries, page)
    assert_equal(2, paginated_vaccines.size)
    assert_not paginated_vaccines.respond_to?(:total_entries)
  end

  test 'paginate: paginates data based on entries and page' do
    patient = create(:patient)
    5.times { create(:vaccine, patient: patient) }

    # Get a relation to pass to the function
    vaccines = Vaccine.where(patient_id: patient.id)
    entries = 3
    page = 1

    paginated_vaccines = paginate(vaccines, entries, page)
    assert_equal(2, paginated_vaccines.entries.length)

    # If paginated, will be able to access Paginator methods
    assert paginated_vaccines.respond_to?(:total_entries)
    assert_equal(5, paginated_vaccines.total_entries)
  end

  def redefine_constant(mod, constant, value)
    mod.send(:remove_const, constant) if mod.const_defined?(constant)
    mod.const_set(constant, value)
  end
end
