include PatientHelper

class AddTimeZoneToPatients < ActiveRecord::Migration[6.0]
  def up
    # Default to Massachusetts time zone if monitored_address_state or address_state 
    # cannot be used to set the patient time zone.
    add_column :patients, :time_zone, :string, default: 'America/New_York'

    PatientHelper.state_names.each_key do |state|
      # Following the logic of Patient#address_timezone_offset: 1) Monitored Address 2) Address State
      patients_in_state = Patient.where(
        purged: false, 
        monitored_address_state: state
      )
      .or(
        Patient.where(
          purged: false, 
          address_state: state
        )
        .where('monitored_address_state IS NULL OR monitored_address_state = ""')
      )
      patients_in_state.update_all(time_zone: PatientHelper.time_zone_for_state(state))
    end
  end

  def down
    remove_column :patients, :time_zone
  end
end
