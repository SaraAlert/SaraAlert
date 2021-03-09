# frozen_string_literal: true

# Helper methods for vaccine-related queries
module VaccineQueryHelper
  # Validates the request params for the index action
  def validate_vaccines_query(params)
    permitted_params = params.permit(:entries, :page, :search, :order, :direction)

    patient_id = params.require(:patient_id)&.to_i
    search_text = permitted_params[:search]
    sort_order = permitted_params[:order]
    sort_direction = permitted_params[:direction]
    # Assume default values if pagination data is not explicitly specified
    entries = permitted_params[:entries]&.to_i || 10
    page = permitted_params[:page]&.to_i || 0

    if sort_direction.present? && !%w[asc desc].include?(sort_direction)
      error_message = "Unable to sort column in specified direction in request: '#{sort_direction}'"
      raise StandardError, error_message
    end

    if sort_order.present? && !%w[id group_name product_name administration_date dose_number notes].include?(sort_order)
      error_message = "Unable to sort by specified column in request: '#{sort_order}'"
      raise StandardError, error_message
    end

    # Either both the sort order and direction are provided, or neither is provided
    if (sort_direction.blank? && sort_order.present?) || (sort_direction.present? && sort_order.blank?)
      error_message = 'Must have both a sort column and direction specified or neither specified. Requested column to sort: '\
                      "'#{sort_order}'', with specified direction: '#{sort_direction}'"
      raise StandardError, error_message
    end

    if entries.negative? || page.negative?
      error_message = "Invalid pagination options. Number of entries: #{entries}. Page: #{page}"
      raise StandardError, error_message
    end

    {
      patient_id: patient_id,
      search_text: search_text,
      sort_order: sort_order,
      sort_direction: sort_direction,
      entries: entries,
      page: page
    }
  end

  # Queries vaccines by ID or type based on search text.
  def search(vaccines, search)
    return vaccines if search.blank?

    vaccines.where('id like ?', "#{search&.downcase}%").or(
      vaccines.where('product_name like ?', "%#{search&.downcase}%").or(
        vaccines.where('group_name like ?', "%#{search&.downcase}%")
      )
    )
  end

  # Sorts vaccines based on given column and direction.
  def sort(vaccines, order, direction)
    # Order by created_at date by default
    return vaccines.order(created_at: 'desc') if order.blank? || direction.blank?

    # Satisfy brakeman with additional sanitation logic
    dir = direction == 'asc' ? 'asc' : 'desc'

    case order
    when 'id'
      vaccines = vaccines.order(id: dir)
    when 'group_name'
      vaccines = vaccines.order(group_name: dir)
    when 'product_name'
      vaccines = vaccines.order(product_name: dir)
    when 'administration_date'
      vaccines = vaccines.order(Arel.sql('CASE WHEN administration_date IS NULL THEN 1 ELSE 0 END, administration_date ' + dir))
    when 'dose_number'
      # nil or empty string values are always sorted at the bottom
      vaccines = vaccines.order(Arel.sql("CASE WHEN dose_number IS NULL THEN 2 WHEN dose_number = '' THEN 1 ELSE 0 END, dose_number " + dir))
    when 'notes'
      # nil or empty string values are always sorted at the bottom
      vaccines = vaccines.order(Arel.sql("CASE WHEN notes IS NULL THEN 2 WHEN notes = '' THEN 1 ELSE 0 END, notes " + dir))
    end
    vaccines
  end

  # Paginates vaccine data.
  def paginate(vaccines, entries, page)
    return vaccines if entries.blank? || entries <= 0 || page.blank? || page.negative?

    vaccines.paginate(per_page: entries, page: page + 1)
  end
end
