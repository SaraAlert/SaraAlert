# frozen_string_literal: true

namespace :stats do
  task eval_queries: :environment do
    ids = ENV['ids']&.split(',')&.collect { |id| id.to_i }

    raise 'You must provide at least one id (e.g. ids=1,2,3)' if ids.nil? || ids.empty?

    start = Date.parse(ENV['start']) rescue nil

    raise 'You must provide a start date (e.g. start=2020-01-01)' if start.nil?

    today = 6.hours.ago.in_time_zone('Eastern Time (US & Canada)').strftime("%m-%d-%Y")

    jurisdictions = Jurisdiction.where(id: ids)

    jurisdictions.each do |jur|
      results = {}

      title = 'LINELISTS: Daily snapshots'
      results[title] = {}
      results[title]['Total'] = {
        exposure: jur.all_patients.where(isolation: false).count,
        isolation: jur.all_patients.where(isolation: true).count
      }
      results[title]['Symptomatic'] = {
        exposure: jur.all_patients.exposure_symptomatic.count,
        isolation: 'N/A'
      }
      results[title]['Non Reporting'] = {
        exposure: jur.all_patients.exposure_non_reporting.count,
        isolation: 'N/A'
      }
      results[title]['Asymptomatic'] = {
        exposure: jur.all_patients.exposure_asymptomatic.count,
        isolation: 'N/A'
      }
      results[title]['Under Investigation (PUI)'] = {
        exposure: jur.all_patients.exposure_under_investigation.count,
        isolation: 'N/A'
      }
      results[title]['Closed'] = {
        exposure: jur.all_patients.monitoring_closed_without_purged.where(isolation: false).count,
        isolation: 'N/A'
      }
      results[title]['Transferred In'] = {
        exposure: jur.transferred_in_patients.where(isolation: false).count,
        isolation: 'N/A'
      }
      results[title]['Transferred Out'] = {
        exposure: jur.transferred_out_patients.where(isolation: false).count,
        isolation: 'N/A'
      }
      results[title]['Continuous Monitoring'] = {
        exposure: jur.all_patients.where(isolation: false, continuous_exposure: true).count,
        isolation: 'N/A'
      }
      results[title]['Requiring Review'] = {
        exposure: 'N/A',
        isolation: jur.all_patients.isolation_requiring_review.count
      }
      results[title]['Reporting'] = {
        exposure: 'N/A',
        isolation: jur.all_patients.isolation_reporting.count
      }
      results[title]['Non Reporting'] = {
        exposure: 'N/A',
        isolation: jur.all_patients.isolation_non_reporting.count
      }
      results[title]['Closed'] = {
        exposure: 'N/A',
        isolation: jur.all_patients.monitoring_closed_without_purged.where(isolation: true).count
      }
      results[title]['Transferred In'] = {
        exposure: 'N/A',
        isolation: jur.transferred_in_patients.where(isolation: true).count
      }
      results[title]['Transferred Out'] = {
        exposure: 'N/A',
        isolation: jur.transferred_out_patients.where(isolation: true).count
      }
      results[title]['Previously in Exposure'] = {
        exposure: 'N/A',
        isolation: jur.all_patients.where(isolation: true).where_assoc_exists(:histories, &:exposure_to_isolation).count
      }

      title = "MONITORING ACTIVITY: Cohort of monitorees existing or added during 14 day period\nINCLUDING Opt-out or Unknown reporting methods"
      results[title] = {}
      results[title]['Total'] = {
        exposure: jur.all_patients.where(isolation: false).count,
        isolation: jur.all_patients.where(isolation: true).count
      }
      results[title]['New today'] = {
        exposure: jur.all_patients.where(isolation: false, created_at: (24.hours.ago)..(DateTime.now)).count,
        isolation: jur.all_patients.where(isolation: true, created_at: (24.hours.ago)..(DateTime.now)).count
      }
      results[title]['New today enrolled by user'] = {
        exposure: jur.all_patients.where(isolation: false, created_at: (24.hours.ago)..(DateTime.now)).where_assoc_exists(:histories, &:user_enrolled_last_24h).count,
        isolation: jur.all_patients.where(isolation: true, created_at: (24.hours.ago)..(DateTime.now)).where_assoc_exists(:histories, &:user_enrolled_last_24h).count
      }
      results[title]['New today enrolled by API'] = {
        exposure: jur.all_patients.where(isolation: false, created_at: (24.hours.ago)..(DateTime.now)).where_assoc_exists(:histories, &:api_enrolled_last_24h).count,
        isolation: jur.all_patients.where(isolation: true, created_at: (24.hours.ago)..(DateTime.now)).where_assoc_exists(:histories, &:api_enrolled_last_24h).count
      }
      results[title]['Total with activity today'] = {
        exposure: jur.all_patients.where(isolation: false).where_assoc_exists(:histories) { user_generated_since(24.hours.ago) }.count,
        isolation: jur.all_patients.where(isolation: true).where_assoc_exists(:histories) { user_generated_since(24.hours.ago) }.count
      }
      results[title]['Total with activity since start of evaluation'] = {
        exposure: jur.all_patients.where(isolation: false).where_assoc_exists(:histories) { user_generated_since(start) }.count,
        isolation: jur.all_patients.where(isolation: true).where_assoc_exists(:histories) { user_generated_since(start) }.count
      }
      results[title]['Closed today - Enrolled more than 14 days after last date of exposure (system)'] = {
        exposure: jur.all_patients.where(monitoring: false, monitoring_reason: 'Enrolled more than 14 days after last date of exposure (system)').where_assoc_exists(:histories, &:system_closed_last_24h).count,
        isolation: 'N/A'
      }
      results[title]['Closed today - Enrolled on last day of monitoring period (system)'] = {
        exposure: jur.all_patients.where(monitoring: false, monitoring_reason: 'Enrolled on last day of monitoring period (system)').where_assoc_exists(:histories, &:system_closed_last_24h).count,
        isolation: 'N/A'
      }
      results[title]['Closed today - Completed Monitoring (system)'] = {
        exposure: jur.all_patients.where(monitoring: false, monitoring_reason: 'Completed Monitoring (system)').where_assoc_exists(:histories, &:system_closed_last_24h).count,
        isolation: 'N/A'
      }
      results[title]['Closed today - manually'] = {
        exposure: jur.all_patients.where(isolation: false, monitoring: false).where_assoc_exists(:histories, &:user_closed_last_24h).count,
        isolation: jur.all_patients.where(isolation: true, monitoring: false).where_assoc_exists(:histories, &:user_closed_last_24h).count
      }

      title = "REPORTING: Cohort of monitorees existing or added during 14 day period\nEXCLUDING Opt-out or Unknown reporting methods"
      results[title] = {}
      active_exp = jur.all_patients.where(monitoring: true, isolation: false).where('patients.updated_at >= ?', start.to_time.beginning_of_day).where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
      active_iso = jur.all_patients.where(monitoring: true, isolation: true).where('patients.updated_at >= ?', start.to_time.beginning_of_day).where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
      results[title]['Total'] = {
        exposure: active_exp.count,
        isolation: active_iso.count
      }
      results[title]['Number of monitorees who responded to at least 1 message (monitoree or proxy response only)'] = {
        exposure: active_exp.where_assoc_exists(:assessments, &:created_by_monitoree).count,
        isolation: active_iso.where_assoc_exists(:assessments, &:created_by_monitoree).count
      }
      results[title]['Number of monitorees who responded to at least 1 message (any response documented, including by public health user)'] = {
        exposure: active_exp.where_assoc_exists(:assessments).count,
        isolation: active_iso.where_assoc_exists(:assessments).count
      }
      results[title]['Monitorees who were sent a report reminder today'] = {
        exposure: active_exp.where_assoc_exists(:histories) { reminder_sent_since(24.hours.ago) }.count,
        isolation: active_iso.where_assoc_exists(:histories) { reminder_sent_since(24.hours.ago) }.count
      }
      results[title]['Monitorees who reported today (monitoree or proxy response only)'] = {
        exposure: active_exp.where_assoc_exists(:assessments, &:created_by_monitoree).where_assoc_exists(:assessments) {created_since(24.hours.ago)}.count,
        isolation: active_iso.where_assoc_exists(:assessments, &:created_by_monitoree).where_assoc_exists(:assessments) {created_since(24.hours.ago)}.count
      }
      results[title]['Monitorees who reported today (any response documented, including by public health user)'] = {
        exposure: active_exp.where_assoc_exists(:assessments) {created_since(24.hours.ago)}.count,
        isolation: active_iso.where_assoc_exists(:assessments) {created_since(24.hours.ago)}.count
      }
      responded_to_all_reminders_self_exp = 0
      responded_to_all_reminders_self_and_user_exp = 0
      not_respond_to_all_reminders_self_exp = 0
      not_respond_to_all_reminders_self_and_user_exp = 0
      days_no_response_self_exp = []
      days_no_response_self_and_user_exp = []
      cons_days_no_response_self_exp = []
      cons_days_no_response_self_and_user_exp = []
      emailed_rates_exp = []
      sms_weblink_rates_exp = []
      phone_rates_exp = []
      sms_text_rates_exp = []
      overall_rates_exp = []
      enrollment_to_lde_exp = []
      enrollment_to_first_rep_exp = []
      active_exp.find_each do |patient|
        times_sent = patient.histories.reminder_sent_since(start).pluck(:created_at).collect { |ca| ca.to_date }.uniq
        times_recv_self = patient.assessments.created_since(start).pluck(:created_at).collect { |ca| ca.to_date }.uniq
        times_recv_self_and_user = patient.assessments.created_since(start).created_by_monitoree.pluck(:created_at).collect { |ca| ca.to_date }.uniq
        responded_to_all_reminders_self_exp += 1 if times_sent.count == times_recv_self.count
        responded_to_all_reminders_self_and_user_exp += 1 if times_sent.count == times_recv_self_and_user.count
        not_respond_to_all_reminders_self_exp += 1 unless times_sent.count == times_recv_self.count
        not_respond_to_all_reminders_self_and_user_exp += 1 unless times_sent.count == times_recv_self_and_user.count
        days_no_response_self_exp << times_sent.count - times_recv_self.count unless times_sent.count == times_recv_self.count
        days_no_response_self_and_user_exp << times_sent.count - times_recv_self_and_user.count unless times_sent.count == times_recv_self_and_user.count
        if times_sent.count != times_recv_self.count
          all_cons = []
          last_cons = 0
          missed_times = (times_sent - times_recv_self)
          missed_times.each_cons(2) { |a, b| (b.mjd - a.mjd) == 1 ? last_cons += ( last_cons == 0 ? 2 : 1) : (all_cons << last_cons && last_cons = 0) }
          all_cons << (last_cons == 0 ? 1 : last_cons) unless missed_times.count == 0
          cons_days_no_response_self_exp << all_cons.inject{ |sum, el| sum + el }.to_f / all_cons.size unless all_cons.empty?
        end
        if times_sent.count != times_recv_self_and_user.count
          all_cons = []
          last_cons = 0
          missed_times = (times_sent - times_recv_self_and_user)
          missed_times.each_cons(2) { |a, b| (b.mjd - a.mjd) == 1 ? last_cons += ( last_cons == 0 ? 2 : 1) : (all_cons << last_cons && last_cons = 0) }
          all_cons << (last_cons == 0 ? 1 : last_cons) unless missed_times.count == 0
          cons_days_no_response_self_and_user_exp << all_cons.inject{ |sum, el| sum + el }.to_f / all_cons.size unless all_cons.empty?
        end
        emailed_rates_exp << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'E-mailed Web Link'
        sms_weblink_rates_exp << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'SMS Texted Weblink'
        phone_rates_exp << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'Telephone call'
        sms_text_rates_exp << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'SMS Text-message'
        overall_rates_exp << times_recv_self_and_user.count / times_sent.count.to_f
        enrollment_to_lde_exp << (patient.created_at.to_date - patient.last_date_of_exposure.to_date).to_i
        enrollment_to_first_rep_exp << (times_recv_self_and_user.first - patient.created_at.to_date).to_i
      end
      responded_to_all_reminders_self_iso = 0
      responded_to_all_reminders_self_and_user_iso = 0
      not_respond_to_all_reminders_self_iso = 0
      not_respond_to_all_reminders_self_and_user_iso = 0
      days_no_response_self_iso = []
      days_no_response_self_and_user_iso = []
      cons_days_no_response_self_iso = []
      cons_days_no_response_self_and_user_iso = []
      emailed_rates_iso = []
      sms_weblink_rates_iso = []
      phone_rates_iso = []
      sms_text_rates_iso = []
      overall_rates_iso = []
      enrollment_to_first_rep_iso = []
      active_iso.find_each do |patient|
        times_sent = patient.histories.reminder_sent_since(start).pluck(:created_at).collect { |ca| ca.to_date }.uniq
        times_recv_self = patient.assessments.created_since(start).pluck(:created_at).collect { |ca| ca.to_date }.uniq
        times_recv_self_and_user = patient.assessments.created_since(start).created_by_monitoree.pluck(:created_at).collect { |ca| ca.to_date }.uniq
        responded_to_all_reminders_self_iso += 1 if times_sent.count == times_recv_self.count
        responded_to_all_reminders_self_and_user_iso += 1 if times_sent.count == times_recv_self_and_user.count
        not_respond_to_all_reminders_self_iso += 1 unless times_sent.count == times_recv_self.count
        not_respond_to_all_reminders_self_and_user_iso += 1 unless times_sent.count == times_recv_self_and_user.count
        days_no_response_self_iso << times_sent.count - times_recv_self.count unless times_sent.count == times_recv_self.count
        days_no_response_self_and_user_iso << times_sent.count - times_recv_self_and_user.count unless times_sent.count == times_recv_self_and_user.count
        if times_sent.count != times_recv_self.count
          all_cons = []
          last_cons = 0
          missed_times = (times_sent - times_recv_self)
          missed_times.each_cons(2) { |a, b| (b.mjd - a.mjd) == 1 ? last_cons += ( last_cons == 0 ? 2 : 1) : (all_cons << last_cons && last_cons = 0) }
          all_cons << (last_cons == 0 ? 1 : last_cons) unless missed_times.count == 0
          cons_days_no_response_self_iso << all_cons.inject{ |sum, el| sum + el }.to_f / all_cons.size unless all_cons.empty?
        end
        if times_sent.count != times_recv_self_and_user.count
          all_cons = []
          last_cons = 0
          missed_times = (times_sent - times_recv_self_and_user)
          missed_times.each_cons(2) { |a, b| (b.mjd - a.mjd) == 1 ? last_cons += ( last_cons == 0 ? 2 : 1) : (all_cons << last_cons && last_cons = 0) }
          all_cons << (last_cons == 0 ? 1 : last_cons) unless missed_times.count == 0
          cons_days_no_response_self_and_user_iso << all_cons.inject{ |sum, el| sum + el }.to_f / all_cons.size unless all_cons.empty?
        end
        emailed_rates_iso << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'E-mailed Web Link'
        sms_weblink_rates_iso << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'SMS Texted Weblink'
        phone_rates_iso << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'Telephone call'
        sms_text_rates_iso << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'SMS Text-message'
        overall_rates_iso << times_recv_self_and_user.count / times_sent.count.to_f
        enrollment_to_first_rep_iso << (times_recv_self_and_user.first - patient.created_at.to_date).to_i
      end
      results[title]['Number of monitorees responding to ALL automated messages (monitoree or proxy response only)'] = {
        exposure: responded_to_all_reminders_self_exp,
        isolation: responded_to_all_reminders_self_iso
      }
      results[title]['Number of monitorees responding to ALL automated messages (any response documented, including by public health user)'] = {
        exposure: responded_to_all_reminders_self_and_user_exp,
        isolation: responded_to_all_reminders_self_and_user_iso
      }
      results[title]['Number of Monitorees who DID NOT RESPOND to all daily automated messages (monitoree or proxy response only)'] = {
        exposure: not_respond_to_all_reminders_self_exp,
        isolation: not_respond_to_all_reminders_self_iso
      }
      results[title]['Number of Monitorees who DID NOT RESPOND to all daily automated messages (monitoree or proxy response only) - Mean number of days with no response'] = {
        exposure: days_no_response_self_exp.inject{ |sum, el| sum + el }.to_f / days_no_response_self_exp.size,
        isolation: days_no_response_self_iso.inject{ |sum, el| sum + el }.to_f / days_no_response_self_iso.size
      }
      results[title]['Number of Monitorees who DID NOT RESPOND to all daily automated messages (monitoree or proxy response only) - Mean number of consecutive days with no response'] = {
        exposure: days_no_response_self_and_user_exp.inject{ |sum, el| sum + el }.to_f / days_no_response_self_and_user_exp.size,
        isolation: days_no_response_self_and_user_iso.inject{ |sum, el| sum + el }.to_f / days_no_response_self_and_user_iso.size
      }
      results[title]['Number of Monitorees who DID NOT RESPOND to all automated messages (any response documented, including by public health user)'] = {
        exposure: not_respond_to_all_reminders_self_and_user_exp,
        isolation: not_respond_to_all_reminders_self_and_user_iso
      }
      results[title]['Number of Monitorees who DID NOT RESPOND to all automated messages (any response documented, including by public health user) - Mean number of days with no response'] = {
        exposure: cons_days_no_response_self_exp.inject{ |sum, el| sum + el }.to_f / cons_days_no_response_self_exp.size,
        isolation: cons_days_no_response_self_iso.inject{ |sum, el| sum + el }.to_f / cons_days_no_response_self_iso.size
      }
      results[title]['Number of Monitorees who DID NOT RESPOND to all automated messages (any response documented, including by public health user) - Mean number of consecutive days with no response'] = {
        exposure: cons_days_no_response_self_and_user_exp.inject{ |sum, el| sum + el }.to_f / cons_days_no_response_self_and_user_exp.size,
        isolation: cons_days_no_response_self_and_user_iso.inject{ |sum, el| sum + el }.to_f / cons_days_no_response_self_and_user_iso.size
      }
      results[title]['Monitoree Response Rate - E-mailed Web Link'] = {
        exposure: emailed_rates_exp.inject{ |sum, el| sum + el }.to_f / emailed_rates_exp.size,
        isolation: emailed_rates_iso.inject{ |sum, el| sum + el }.to_f / emailed_rates_iso.size
      }
      results[title]['Monitoree Response Rate - SMS Texted Weblink'] = {
        exposure: sms_weblink_rates_exp.inject{ |sum, el| sum + el }.to_f / sms_weblink_rates_exp.size,
        isolation: sms_weblink_rates_iso.inject{ |sum, el| sum + el }.to_f / sms_weblink_rates_iso.size
      }
      results[title]['Monitoree Response Rate - Telephone call'] = {
        exposure: phone_rates_exp.inject{ |sum, el| sum + el }.to_f / phone_rates_exp.size,
        isolation: phone_rates_iso.inject{ |sum, el| sum + el }.to_f / phone_rates_iso.size
      }
      results[title]['Monitoree Response Rate - SMS Text-message'] = {
        exposure: sms_text_rates_exp.inject{ |sum, el| sum + el }.to_f / sms_text_rates_exp.size,
        isolation: sms_text_rates_iso.inject{ |sum, el| sum + el }.to_f / sms_text_rates_iso.size
      }
      results[title]['Monitoree Response Rate - Overall'] = {
        exposure: overall_rates_exp.inject{ |sum, el| sum + el }.to_f / overall_rates_exp.size,
        isolation: overall_rates_iso.inject{ |sum, el| sum + el }.to_f / overall_rates_iso.size
      }
      results[title]['Number of monitorees reporting symptoms consistent with COVID-19 case definition'] = {
        exposure: active_exp.where_assoc_exists(:assessments, symptomatic: true).count,
        isolation: active_iso.where_assoc_exists(:assessments, symptomatic: true).count
      }
      results[title]['Number of monitorees with symptomatic reports marked as reviewed'] = {
        exposure: active_exp.where_assoc_exists(:histories) { reports_reviewed_since(start) }.count,
        isolation: active_iso.where_assoc_exists(:histories) { reports_reviewed_since(start) }.count
      }
      results[title]['Time between last date of exposure and enrollment in monitoring (days)'] = {
        exposure: enrollment_to_lde_exp.inject{ |sum, el| sum + el }.to_f / enrollment_to_lde_exp.size,
        isolation: 'N/A'
      }
      results[title]['Time between create date and first report by monitoree'] = {
        exposure: enrollment_to_first_rep_exp.inject{ |sum, el| sum + el }.to_f / enrollment_to_first_rep_exp.size,
        isolation: enrollment_to_first_rep_iso.inject{ |sum, el| sum + el }.to_f / enrollment_to_first_rep_iso.size
      }
      results[title]['Number of monitorees with any action other than none in their history'] = {
        exposure: active_exp.where.not(public_health_action: 'None').count,
        isolation: active_iso.where.not(public_health_action: 'None').count
      }

      title = "DEMOGRAPHICS: Cohort of monitorees existing or added during 14 day period\nEXCLUDING Opt-out or Unknown reporting methods"
      results[title] = {}
      active_exp = jur.all_patients.where(monitoring: true, isolation: false).where('patients.updated_at >= ?', start.to_time.beginning_of_day).where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
      active_iso = jur.all_patients.where(monitoring: true, isolation: true).where('patients.updated_at >= ?', start.to_time.beginning_of_day).where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
      results[title]['Total'] = {
        exposure: active_exp.count,
        isolation: active_iso.count
      }
      results[title]['Sex - Male'] = {
        exposure: active_exp.where(sex: 'Male').count,
        isolation: active_iso.where(sex: 'Male').count
      }
      results[title]['Sex - Female'] = {
        exposure: active_exp.where(sex: 'Female').count,
        isolation: active_iso.where(sex: 'Female').count
      }
      results[title]['Sex - Unknown'] = {
        exposure: active_exp.where(sex: 'Unknown').count,
        isolation: active_iso.where(sex: 'Unknown').count
      }
      results[title]['Sex - blank'] = {
        exposure: active_exp.where(sex: [nil, '']).count,
        isolation: active_iso.where(sex: [nil, '']).count
      }
      results[title]['Race - White only'] = {
        exposure: active_exp.where(white: true, black_or_african_american: [false, nil], american_indian_or_alaska_native: [false, nil], asian: [false, nil], native_hawaiian_or_other_pacific_islander: [false, nil]).count,
        isolation: active_iso.where(white: true, black_or_african_american: [false, nil], american_indian_or_alaska_native: [false, nil], asian: [false, nil], native_hawaiian_or_other_pacific_islander: [false, nil]).count
      }
      results[title]['Race - Black or African American only'] = {
        exposure: active_exp.where(white: [false, nil], black_or_african_american: true, american_indian_or_alaska_native: [false, nil], asian: [false, nil], native_hawaiian_or_other_pacific_islander: [false, nil]).count,
        isolation: active_iso.where(white: [false, nil], black_or_african_american: true, american_indian_or_alaska_native: [false, nil], asian: [false, nil], native_hawaiian_or_other_pacific_islander: [false, nil]).count
      }
      results[title]['Race - American Indian or Alaska Native only'] = {
        exposure: active_exp.where(white: [false, nil], black_or_african_american: [false, nil], american_indian_or_alaska_native: true, asian: [false, nil], native_hawaiian_or_other_pacific_islander: [false, nil]).count,
        isolation: active_iso.where(white: [false, nil], black_or_african_american: [false, nil], american_indian_or_alaska_native: true, asian: [false, nil], native_hawaiian_or_other_pacific_islander: [false, nil]).count
      }
      results[title]['Race - Asian only'] = {
        exposure: active_exp.where(white: [false, nil], black_or_african_american: [false, nil], american_indian_or_alaska_native: [false, nil], asian: true, native_hawaiian_or_other_pacific_islander: [false, nil]).count,
        isolation: active_iso.where(white: [false, nil], black_or_african_american: [false, nil], american_indian_or_alaska_native: [false, nil], asian: true, native_hawaiian_or_other_pacific_islander: [false, nil]).count
      }
      results[title]['Race - Native Hawaiian or Pacific Islander only'] = {
        exposure: active_exp.where(white: [false, nil], black_or_african_american: [false, nil], american_indian_or_alaska_native: [false, nil], asian: [false, nil], native_hawaiian_or_other_pacific_islander: true).count,
        isolation: active_iso.where(white: [false, nil], black_or_african_american: [false, nil], american_indian_or_alaska_native: [false, nil], asian: [false, nil], native_hawaiian_or_other_pacific_islander: true).count
      }
      results[title]['Race - Missing'] = {
        exposure: active_exp.where(white: [false, nil], black_or_african_american: [false, nil], american_indian_or_alaska_native: [false, nil], asian: [false, nil], native_hawaiian_or_other_pacific_islander: [false, nil]).count,
        isolation: active_iso.where(white: [false, nil], black_or_african_american: [false, nil], american_indian_or_alaska_native: [false, nil], asian: [false, nil], native_hawaiian_or_other_pacific_islander: [false, nil]).count
      }
      results[title]['Race - More than one'] = {
        exposure: active_exp.count - (results[title]['Race - White only'][:exposure] + results[title]['Race - Black or African American only'][:exposure] + results[title]['Race - American Indian or Alaska Native only'][:exposure] + results[title]['Race - Asian only'][:exposure] + results[title]['Race - Native Hawaiian or Pacific Islander only'][:exposure] + results[title]['Race - Missing'][:exposure]),
        isolation: active_iso.count - (results[title]['Race - White only'][:isolation] + results[title]['Race - Black or African American only'][:isolation] + results[title]['Race - American Indian or Alaska Native only'][:isolation] + results[title]['Race - Asian only'][:isolation] + results[title]['Race - Native Hawaiian or Pacific Islander only'][:isolation] + results[title]['Race - Missing'][:isolation])
      }
      results[title]['Ethnicity - Hispanic or Latino'] = {
        exposure: active_exp.where(ethnicity: 'Hispanic or Latino').count,
        isolation: active_iso.where(ethnicity: 'Hispanic or Latino').count
      }
      results[title]['Ethnicity - Not Hispanic or Latino'] = {
        exposure: active_exp.where(ethnicity: 'Not Hispanic or Latino').count,
        isolation: active_iso.where(ethnicity: 'Not Hispanic or Latino').count
      }
      results[title]['Ethnicity - blank'] = {
        exposure: active_exp.where(ethnicity: ['', nil]).count,
        isolation: active_iso.where(ethnicity: ['', nil]).count
      }
      results[title]['Missing All Demographics (blank sex, ethnicity, and race)'] = {
        exposure: active_exp.where(sex: ['', nil], ethnicity: ['', nil], white: [false, nil], black_or_african_american: [false, nil], american_indian_or_alaska_native: [false, nil], asian: [false, nil], native_hawaiian_or_other_pacific_islander: [false, nil]).count,
        isolation: active_iso.where(sex: ['', nil], ethnicity: ['', nil], white: [false, nil], black_or_african_american: [false, nil], american_indian_or_alaska_native: [false, nil], asian: [false, nil], native_hawaiian_or_other_pacific_islander: [false, nil]).count
      }
      results[title]['Age - <= 18'] = {
        exposure: active_exp.where('date_of_birth > ?', 19.years.ago).count,
        isolation: active_iso.where('date_of_birth > ?', 19.years.ago).count
      }
      results[title]['Age - 19-29'] = {
        exposure: active_exp.where('date_of_birth <= ?', 19.years.ago).where('date_of_birth > ?', 30.years.ago).count,
        isolation: active_iso.where('date_of_birth <= ?', 19.years.ago).where('date_of_birth > ?', 30.years.ago).count
      }
      results[title]['Age - 30-39'] = {
        exposure: active_exp.where('date_of_birth <= ?', 30.years.ago).where('date_of_birth > ?', 40.years.ago).count,
        isolation: active_iso.where('date_of_birth <= ?', 30.years.ago).where('date_of_birth > ?', 40.years.ago).count
      }
      results[title]['Age - 40-49'] = {
        exposure: active_exp.where('date_of_birth <= ?', 40.years.ago).where('date_of_birth > ?', 50.years.ago).count,
        isolation: active_iso.where('date_of_birth <= ?', 40.years.ago).where('date_of_birth > ?', 50.years.ago).count
      }
      results[title]['Age - 50-59'] = {
        exposure: active_exp.where('date_of_birth <= ?', 50.years.ago).where('date_of_birth > ?', 60.years.ago).count,
        isolation: active_iso.where('date_of_birth <= ?', 50.years.ago).where('date_of_birth > ?', 60.years.ago).count
      }
      results[title]['Age - 60-69'] = {
        exposure: active_exp.where('date_of_birth <= ?', 60.years.ago).where('date_of_birth > ?', 70.years.ago).count,
        isolation: active_iso.where('date_of_birth <= ?', 60.years.ago).where('date_of_birth > ?', 70.years.ago).count
      }
      results[title]['Age - 70-79'] = {
        exposure: active_exp.where('date_of_birth <= ?', 70.years.ago).where('date_of_birth > ?', 80.years.ago).count,
        isolation: active_iso.where('date_of_birth <= ?', 70.years.ago).where('date_of_birth > ?', 80.years.ago).count
      }
      results[title]['Age - >= 80'] = {
        exposure: active_exp.where('date_of_birth <= ?', 80.years.ago).where('date_of_birth > ?', 110.years.ago).count,
        isolation: active_iso.where('date_of_birth <= ?', 80.years.ago).where('date_of_birth > ?', 110.years.ago).count
      }
      results[title]['Age - Flagged for possible missing age'] = {
        exposure: active_exp.where('date_of_birth <= ?', 110.years.ago).or(active_exp.where(date_of_birth: ['', nil])).count,
        isolation: active_iso.where('date_of_birth <= ?', 110.years.ago).or(active_exp.where(date_of_birth: ['', nil])).count
      }
      dates_exp = active_exp.where('date_of_birth > ?', 110.years.ago).pluck(:date_of_birth).reject(&:nil?).collect{|dob| dob.to_datetime.to_f}
      dates_iso = active_exp.where('date_of_birth > ?', 110.years.ago).pluck(:date_of_birth).reject(&:nil?).collect{|dob| dob.to_datetime.to_f}
      results[title]['Age - Continuous mean'] = {
        exposure: DateTime.now.year - Date.strptime((dates_exp.sum / dates_exp.count).to_i.to_s, "%s").year,
        isolation: DateTime.now.year - Date.strptime((dates_iso.sum / dates_iso.count).to_i.to_s, "%s").year
      }
      results[title]['Preferred Reporting Method - Telephone call'] = {
        exposure: active_exp.where(preferred_contact_method: 'Telephone call').count,
        isolation: active_iso.where(preferred_contact_method: 'Telephone call').count
      }
      results[title]['Preferred Reporting Method - SMS Text-message'] = {
        exposure: active_exp.where(preferred_contact_method: 'SMS Text-message').count,
        isolation: active_iso.where(preferred_contact_method: 'SMS Text-message').count
      }
      results[title]['Preferred Reporting Method - SMS Texted Weblink'] = {
        exposure: active_exp.where(preferred_contact_method: 'SMS Texted Weblink').count,
        isolation: active_iso.where(preferred_contact_method: 'SMS Texted Weblink').count
      }
      results[title]['Preferred Reporting Method - E-mailed Web Link'] = {
        exposure: active_exp.where(preferred_contact_method: 'E-mailed Web Link').count,
        isolation: active_iso.where(preferred_contact_method: 'E-mailed Web Link').count
      }
      results[title]['Preferred Reporting Time - Morning'] = {
        exposure: active_exp.where(preferred_contact_time: 'Morning').count,
        isolation: active_iso.where(preferred_contact_time: 'Morning').count
      }
      results[title]['Preferred Reporting Time - Afternoon'] = {
        exposure: active_exp.where(preferred_contact_time: 'Afternoon').count,
        isolation: active_iso.where(preferred_contact_time: 'Afternoon').count
      }
      results[title]['Preferred Reporting Time - Evening'] = {
        exposure: active_exp.where(preferred_contact_time: 'Evening').count,
        isolation: active_iso.where(preferred_contact_time: 'Evening').count
      }
      results[title]['Preferred Reporting Time - blank'] = {
        exposure: active_exp.where(preferred_contact_time: ['', nil]).count,
        isolation: active_iso.where(preferred_contact_time: ['', nil]).count
      }
      results[title]['Preferred Language - English'] = {
        exposure: active_exp.where(primary_language: 'English').count,
        isolation: active_iso.where(primary_language: 'English').count
      }
      results[title]['Preferred Language - Spanish'] = {
        exposure: active_exp.where(primary_language: 'Spanish').count,
        isolation: active_iso.where(primary_language: 'Spanish').count
      }
      results[title]['Preferred Language - Spanish (Puerto Rican)'] = {
        exposure: active_exp.where(primary_language: 'Spanish (Puerto Rican)').count,
        isolation: active_iso.where(primary_language: 'Spanish (Puerto Rican)').count
      }
      results[title]['Preferred Language - Other'] = {
        exposure: active_exp.where.not(primary_language: ['', nil, 'English', 'Spanish', 'Spanish (Puerto Rican)']).count,
        isolation: active_iso.where.not(primary_language: ['', nil, 'English', 'Spanish', 'Spanish (Puerto Rican)']).count
      }
      results[title]['Preferred Language - blank'] = {
        exposure: active_exp.where(primary_language: ['', nil]).count,
        isolation: active_iso.where(primary_language: ['', nil]).count
      }

      title = 'USERS: Daily snapshots'
      results[title] = {}
      results[title]['Total'] = { exposure: jur.all_users.where.not(role: [nil, '', 'none']).count, isolation: nil }
      results[title]['Active'] = { exposure: jur.all_users.where(locked_at: nil).where.not(role: [nil, '', 'none']).count, isolation: nil }
      results[title]['Super User'] = { exposure: jur.all_users.where(role: 'super_user').count, isolation: nil }
      results[title]['Public Health Enroller'] = { exposure: jur.all_users.where(role: 'public_health_enroller').count, isolation: nil }
      results[title]['Contact Tracer'] = { exposure: jur.all_users.where(role: 'contact_tracer').count, isolation: nil }
      results[title]['Public Health'] = { exposure: jur.all_users.where(role: 'public_health').count, isolation: nil }
      results[title]['Enroller'] = { exposure: jur.all_users.where(role: 'enroller').count, isolation: nil }
      results[title]['Analyst'] = { exposure: jur.all_users.where(role: 'analyst').count, isolation: nil }
      results[title]['Admins'] = { exposure: jur.all_users.where(role: 'admin').count, isolation: nil }

      json = {}
      json[today] = results
      Stat.create!(contents: json.to_json, jurisdiction_id: jur.id, tag: 'eval_queries')
    end
  end
end
