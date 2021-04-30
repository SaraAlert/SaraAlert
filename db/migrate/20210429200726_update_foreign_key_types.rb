class UpdateForeignKeyTypes < ActiveRecord::Migration[6.1]
  TABLE_COLUMNS = {
    analytics: %i[jurisdiction_id],
    audits: %i[auditable_id associated_id user_id],
    close_contacts: %i[enrolled_id],
    conditions: %i[jurisdiction_id assessment_id],
    oauth_applications: %i[jurisdiction_id],
    patients: %i[responder_id creator_id jurisdiction_id latest_transfer_from],
    stats: %i[jurisdiction_id],
    symptoms: %i[condition_id],
    transfers: %i[from_jurisdiction_id to_jurisdiction_id who_id],
    users: %i[jurisdiction_id]
  }.freeze

  def up
    change_column_type(TABLE_COLUMNS, :bigint)
  end

  def down
    change_column_type(TABLE_COLUMNS, :integer)
  end

  def change_column_type(table_columns, type)
    table_columns.each do |table, columns|
      columns.each do |column|
        change_column table, column, type
      end
    end
  end
end
