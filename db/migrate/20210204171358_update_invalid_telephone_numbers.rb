class UpdateInvalidTelephoneNumbers < ActiveRecord::Migration[6.1]
  def change
    %w[primary_telephone
      secondary_telephone].each do |phone_field|
        Patient.where(purged: false).where.not("#{phone_field} REGEXP ?", '^\\+1(0|[2-9])[0-9]{9}$').each do |patient|
          if patient[phone_field].sub(/^\+/, '').length == 10 && !patient.address_state.nil?
            patient[phone_field] = patient[phone_field].sub(/^\+/, '+1')
            patient.save(validate: false)
          end
        end
    end
  end
end
