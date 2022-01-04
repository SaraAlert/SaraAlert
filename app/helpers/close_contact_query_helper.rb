# frozen_string_literal: true

# Helper methods for filtering through close_contacts
module CloseContactQueryHelper
  def close_contacts_by_patient_ids(patient_ids)
    CloseContact.where(patient_id: patient_ids).order(:patient_id)
  end

  # Validates the request params for the index action
  def validate_close_contact_query(params)
    permitted_params = params.permit(:entries, :page, :search, :order, :direction)

    patient_id = params.require(:patient_id)&.to_i
    search_text = permitted_params[:search]
    sort_order = permitted_params[:order]
    sort_direction = permitted_params[:direction]
    # Assume default values if pagination data is not explicitly specified
    entries = permitted_params[:entries]&.to_i || 10
    page = permitted_params[:page]&.to_i || 0

    if sort_direction.present? && %w[asc desc].exclude?(sort_direction)
      error_message = "Unable to sort column in specified direction in request: '#{sort_direction}'"
      raise StandardError, error_message
    end

    if sort_order.present? && %w[first_name last_name primary_telephone email last_date_of_exposure assigned_user contact_attempts enrolled_id
                                 notes].exclude?(sort_order)
      error_message = "Unable to sort by specified column in request: '#{sort_order}'"
      raise StandardError, error_message
    end

    # Either both the sort order and direction are provided, or neither is provided
    if (sort_direction.blank? && sort_order.present?) || (sort_direction.present? && sort_order.blank?)
      error_message = 'Must have both a sort column and direction specified or neither specified. Requested column to sort: '\
                      "'#{sort_order}'', with specified direction: '#{sort_direction}'"
      raise StandardError, error_message
    end

    raise InvalidQueryError.new(:entries, entries) if entries.negative?
    raise InvalidQueryError.new(:page, page) if page.negative?

    {
      patient_id: patient_id,
      search_text: search_text,
      sort_order: sort_order,
      sort_direction: sort_direction,
      entries: entries,
      page: page
    }
  end

  # Queries close_contact by ID or type based on search text.
  def search(close_contact, search)
    return close_contact if search.blank?

    close_contact.where('first_name like ?', "#{search&.downcase}%").or(
      close_contact.where('last_name like ?', "#{search&.downcase}%").or(
        close_contact.where('primary_telephone like ?', "%#{search}%").or(
          close_contact.where('email like ?', "#{search&.downcase}%").or(
            close_contact.where('assigned_user like ?', "#{search&.downcase}%").or(
              close_contact.where('contact_attempts like ?', "#{search&.downcase}%")
            )
          )
        )
      )
    )
  end

  # Sorts close_contacts based on given column and direction.
  def sort(close_contacts, order, direction)
    # Order by created_at date by default
    return close_contacts.order(created_at: 'desc') if order.blank? || direction.blank?

    # Satisfy brakeman with additional sanitation logic
    dir = direction == 'asc' ? 'asc' : 'desc'

    case order
    when 'first_name'
      close_contacts = close_contacts.order(Arel.sql('first_name IS NULL OR first_name = "", first_name ' + dir))
    when 'last_name'
      close_contacts = close_contacts.order(Arel.sql('last_name IS NULL OR last_name = "", last_name ' + dir))
    when 'primary_telephone'
      close_contacts = close_contacts.order(Arel.sql('primary_telephone IS NULL OR primary_telephone = "", primary_telephone ' + dir))
    when 'email'
      close_contacts = close_contacts.order(Arel.sql('email IS NULL OR email = "", email ' + dir))
    when 'enrolled_id'
      close_contacts = close_contacts.order(Arel.sql('enrolled_id IS NOT NULL ' + dir))
    when 'last_date_of_exposure'
      close_contacts = close_contacts.order(Arel.sql('last_date_of_exposure IS NULL, last_date_of_exposure ' + dir))
    when 'assigned_user'
      close_contacts = close_contacts.order(Arel.sql('assigned_user IS NULL, assigned_user ' + dir))
    when 'contact_attempts'
      close_contacts = close_contacts.order(Arel.sql('contact_attempts IS NULL, contact_attempts ' + dir))
    when 'notes'
      close_contacts = close_contacts.order(Arel.sql('CASE WHEN notes IS NULL THEN 2 WHEN notes = "" THEN 1 ELSE 0 END, notes ' + dir))
    end
    close_contacts
  end

  # Paginates close_contact data.
  def paginate(close_contacts, entries, page)
    return close_contacts if entries.blank? || entries <= 0 || page.blank? || page.negative?

    close_contacts.paginate(per_page: entries, page: page + 1)
  end
end
