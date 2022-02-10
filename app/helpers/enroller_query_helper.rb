# frozen_string_literal: true

# Helper methods for filtering through patients in the enroller table
module EnrollerQueryHelper
  def enroller_table_data(params, current_user)
    query = validate_enroller_query(params.require(:query))

    # Validate pagination params
    entries = params.require(:query)[:entries]&.to_i || 25
    raise InvalidQueryError.new(:entries, entries) unless entries >= 0

    page = params.require(:query)[:page]&.to_i || 0
    raise InvalidQueryError.new(:page, page) unless page >= 0

    # Get filtered patients
    patients = patients_by_query(current_user, query)

    # Paginate
    patients = patients.paginate(per_page: entries, page: page + 1)

    # Extract only relevant fields to be displayed in the enroller table
    enroller_linelist(patients)
  end

  def validate_enroller_query(unsanitized_query)
    # Only allow permitted params
    query = unsanitized_query.permit(:jurisdiction, :scope, :user, :search, :entries, :page, :order, :direction, :tz_offset)

    # Validate jurisdiction
    jurisdiction = query[:jurisdiction]
    unless jurisdiction.nil? || jurisdiction == 'all' || current_user.jurisdiction.subtree_ids.include?(jurisdiction.to_i)
      raise InvalidQueryError.new(:jurisdiction, jurisdiction)
    end

    # Validate jurisdiction scope
    scope = query[:scope]
    raise InvalidQueryError.new(:scope, scope) unless scope.nil? || %w[all exact].include?(scope)

    # Validate assigned user
    user = query[:user]
    raise InvalidQueryError.new(:user, user) unless user.nil? || %w[none].include?(user) || user.to_i.between?(1, 999_999)

    # Validate sorting order
    order = query[:order]
    raise InvalidQueryError.new(:order, order) unless order.nil? || order.blank? || %w[name jurisdiction assigned_user state_local_id sex dob
                                                                                       enrollment_date].include?(order)

    # Validate sorting direction
    direction = query[:direction]
    raise InvalidQueryError.new(:direction, direction) unless direction.blank? || %w[asc desc].include?(direction)
    raise InvalidQueryError.new(:direction, direction) unless (order.present? && direction.present?) || (order.blank? && direction.blank?)

    query
  end

  def patients_by_query(current_user, query)
    # Determine jurisdiction
    jurisdiction = Jurisdiction.find(query[:jurisdiction].to_i) unless ['all', nil].include?(query[:jurisdiction])
    jurisdiction = current_user.jurisdiction if jurisdiction.nil?

    # Get enrolled patients by current user
    patients = current_user.enrolled_patients

    # Filter by assigned jurisdiction
    patients = patients.where(jurisdiction_id: jurisdiction.subtree_ids)

    # Filter by scope
    patients = patients.where(jurisdiction_id: jurisdiction.id) if query[:scope] == 'exact'

    # Filter by assigned user
    patients = patients.where(assigned_user: query[:user] == 'none' ? nil : query[:user].to_i) unless query[:user].nil?

    # Filter by search text
    patients = filter_by_text(patients, query[:search])

    # Sort
    sort(patients, query[:order], query[:direction])
  end

  def filter_by_text(patients, search)
    return patients if search.nil? || search.blank?

    filtered = patients.where('first_name like ?', "#{search&.downcase}%").or(
      patients.where('last_name like ?', "#{search&.downcase}%").or(
        patients.where('user_defined_id_statelocal like ?', "#{search&.downcase}%").or(
          patients.where('user_defined_id_cdc like ?', "#{search&.downcase}%").or(
            patients.where('user_defined_id_nndss like ?', "#{search&.downcase}%").or(
              patients.where('date_of_birth like ?', "#{search&.downcase}%").or(
                patients.where('patients.email like ?', "#{search&.downcase}%")
              )
            )
          )
        )
      )
    )

    phone_query = search.delete('^0-9')
    phone_query.blank? ? filtered : filtered.or(patients.where('primary_telephone like ?', "+1#{phone_query}%"))
  end

  def sort(patients, order, direction)
    return patients if order.blank? || direction.blank?

    # Satisfy brakeman with additional sanitation logic
    dir = direction == 'asc' ? 'asc' : 'desc'

    case order
    when 'name'
      patients = patients.order(last_name: dir, first_name: dir, id: dir)
    when 'jurisdiction'
      patients = patients.includes(:jurisdiction).order('jurisdictions.name ' + dir, id: dir)
    when 'assigned_user'
      patients = patients.order(Arel.sql('assigned_user IS NULL, assigned_user ' + dir), id: dir)
    when 'state_local_id'
      patients = patients.order(Arel.sql('user_defined_id_statelocal IS NULL OR user_defined_id_statelocal = "", user_defined_id_statelocal ' + dir), id: dir)
    when 'sex'
      patients = patients.order(Arel.sql('sex IS NULL OR sex = "", sex ' + dir), id: dir)
    when 'dob'
      patients = patients.order(Arel.sql('date_of_birth IS NULL, date_of_birth ' + dir), id: dir)
    when 'enrollment_date'
      patients = patients.order(Arel.sql('patients.created_at IS NULL, patients.created_at ' + dir), id: dir)
    end

    patients
  end

  def enroller_linelist(patients)
    # get a list of fields relevant only to enroller table
    fields = %i[name jurisdiction assigned_user state_local_id sex dob enrollment_date]

    # retrieve proper jurisdiction
    patients = patients.joins(:jurisdiction)

    # only select patient fields necessary for enroller table
    patients = patients.select('patients.id, patients.first_name, patients.last_name, patients.user_defined_id_statelocal, patients.sex, '\
                               'patients.date_of_birth, patients.assigned_user, patients.created_at, jurisdictions.name AS jurisdiction_name, '\
                               'jurisdictions.path AS jurisdiction_path, jurisdictions.id AS jurisdiction_id')

    # execute query and get total count
    total = patients.total_entries

    linelist = []
    patients.each do |patient|
      linelist << {
        id: patient[:id],
        name: patient.displayed_name,
        jurisdiction: patient[:jurisdiction_name] || '',
        assigned_user: patient[:assigned_user] || '',
        state_local_id: patient[:user_defined_id_statelocal] || '',
        sex: patient[:sex],
        dob: patient[:date_of_birth]&.strftime('%F') || '',
        enrollment_date: patient[:created_at]&.strftime('%F') || ''
      }
    end

    { linelist: linelist, fields: fields, total: total }
  end
end
