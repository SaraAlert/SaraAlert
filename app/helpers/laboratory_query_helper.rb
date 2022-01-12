# frozen_string_literal: true

# Helper methods for filtering through laboratories
module LaboratoryQueryHelper
  def laboratories_by_patient_ids(patient_ids)
    Laboratory.where(patient_id: patient_ids).order(:patient_id)
  end

  # Validates the request params for the index action
  def validate_laboratory_query(params)
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

    if sort_order.present? && %w[id lab_type specimen_collection report result].exclude?(sort_order)
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

  # Queries laboratories by ID or type based on search text.
  def search(laboratories, search)
    return laboratories if search.blank?

    laboratories.where('id like ?', "#{search}%").or(
      laboratories.where('lab_type like ?', "%#{search&.downcase}%").or(
        laboratories.where('result like ?', "%#{search&.downcase}%")
      )
    )
  end

  # Sorts laboratories based on given column and direction.
  def sort(laboratories, order, direction)
    # Order by created_at date by default
    return laboratories.order(created_at: 'desc') if order.blank? || direction.blank?

    # Satisfy brakeman with additional sanitation logic
    dir = direction == 'asc' ? 'asc' : 'desc'

    case order
    when 'id'
      laboratories = laboratories.order(id: dir)
    when 'lab_type'
      laboratories = laboratories.order(Arel.sql('lab_type IS NULL OR lab_type = "", lab_type ' + dir))
    when 'specimen_collection'
      laboratories = laboratories.order(Arel.sql('specimen_collection IS NULL OR specimen_collection = "", specimen_collection ' + dir))
    when 'report'
      laboratories = laboratories.order(Arel.sql('report IS NULL OR report = "", report ' + dir))
    when 'result'
      laboratories = laboratories.order(Arel.sql('result IS NULL OR result = "", result ' + dir))
    end
    laboratories
  end

  # Paginates laboratory data.
  def paginate(laboratories, entries, page)
    return laboratories if entries.blank? || entries <= 0 || page.blank? || page.negative?

    laboratories.paginate(per_page: entries, page: page + 1)
  end
end
