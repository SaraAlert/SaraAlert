# frozen_string_literal: true

namespace :stats do
  task eval_queries: :environment do
    ids = ENV['ids']&.split(',')&.collect { |id| id.to_i } || []
    excludes = ENV['exclude']&.split(',')&.collect { |id| id.to_i } || []
    exclude_ids = excludes.collect { |ex_id| Jurisdiction.find_by(id: ex_id).subtree_ids }.flatten.uniq

    raise 'You must provide at least one id (e.g. ids=1,2,3)' if ids.nil? || ids.empty?

    start = Date.parse(ENV['start']) rescue nil

    raise 'You must provide a start date (e.g. start=2020-01-01)' if start.nil?

    tag = ENV['tag']

    raise 'You must provide a tag (e.g. tag=blah)' if tag.nil?

    today = 6.hours.ago.in_time_zone('Eastern Time (US & Canada)').strftime("%m-%d-%Y")

    jurisdictions = Jurisdiction.where(id: ids)

    jurisdictions.each do |jur|
      results = {}

      jur_patients = jur.all_patients_excluding_purged.where.not(jurisdiction_id: exclude_ids)

      puts 'Step 1 of 6: linelists'
      title = 'LINELISTS: Daily snapshots'
      results[title] = {}
      results[title]['Total'] = {
        exposure: jur_patients.where(isolation: false).count,
        isolation: jur_patients.where(isolation: true).count
      }
      results[title]['Exposure Symptomatic'] = {
        exposure: jur_patients.exposure_symptomatic.count,
        isolation: 'N/A'
      }
      results[title]['Exposure Non-Reporting'] = {
        exposure: jur_patients.exposure_non_reporting.count,
        isolation: 'N/A'
      }
      results[title]['Exposure Asymptomatic'] = {
        exposure: jur_patients.exposure_asymptomatic.count,
        isolation: 'N/A'
      }
      results[title]['Exposure Under Investigation (PUI)'] = {
        exposure: jur_patients.exposure_under_investigation.count,
        isolation: 'N/A'
      }
      results[title]['Exposure Closed'] = {
        exposure: jur_patients.monitoring_closed_without_purged.where(isolation: false).count,
        isolation: 'N/A'
      }
      results[title]['Exposure Transferred In'] = {
        exposure: jur.transferred_in_patients.where(isolation: false).where.not(jurisdiction_id: exclude_ids).count,
        isolation: 'N/A'
      }
      results[title]['Exposure Transferred Out'] = {
        exposure: jur.transferred_out_patients.where(isolation: false).where.not(jurisdiction_id: exclude_ids).count,
        isolation: 'N/A'
      }
      results[title]['Exposure Continuous Monitoring'] = {
        exposure: jur_patients.where(isolation: false, continuous_exposure: true).count,
        isolation: 'N/A'
      }
      results[title]['Isolation Requires Review'] = {
        exposure: 'N/A',
        isolation: jur_patients.isolation_requiring_review.count
      }
      results[title]['Isolation Reporting'] = {
        exposure: 'N/A',
        isolation: jur_patients.isolation_reporting.count
      }
      results[title]['Isolation Non-Reporting'] = {
        exposure: 'N/A',
        isolation: jur_patients.isolation_non_reporting.count
      }
      results[title]['Isolation Closed'] = {
        exposure: 'N/A',
        isolation: jur_patients.monitoring_closed_without_purged.where(isolation: true).count
      }
      results[title]['Isolation Transferred In'] = {
        exposure: 'N/A',
        isolation: jur.transferred_in_patients.where(isolation: true).where.not(jurisdiction_id: exclude_ids).count
      }
      results[title]['Isolation Transferred Out'] = {
        exposure: 'N/A',
        isolation: jur.transferred_out_patients.where(isolation: true).where.not(jurisdiction_id: exclude_ids).count
      }
      results[title]['Isolation Previously in Exposure EXCLUDING closed'] = {
        exposure: 'N/A',
        isolation: jur_patients.where(monitoring: true, isolation: true).where_assoc_exists(:histories, &:exposure_to_isolation).count
      }

      puts 'Step 2 of 6: monitoring activity'
      title = "MONITORING ACTIVITY: Cohort of monitorees existing or added during 14 day period EXCLUDING Opt-out or Unknown reporting methods"
      results[title] = {}
      activity_exp = jur_patients.where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
      activity_iso = jur_patients.where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
      results[title]['Total'] = {
        exposure: activity_exp.where(isolation: false).count,
        isolation: activity_iso.where(isolation: true).count
      }
      results[title]['New today'] = {
        exposure: activity_exp.where(isolation: false, created_at: (24.hours.ago)..(DateTime.now)).count,
        isolation: activity_iso.where(isolation: true, created_at: (24.hours.ago)..(DateTime.now)).count
      }
      results[title]['New today enrolled by user'] = {
        exposure: activity_exp.where(isolation: false, created_at: (24.hours.ago)..(DateTime.now)).where_assoc_exists(:histories, &:user_enrolled_last_24h).count,
        isolation: activity_iso.where(isolation: true, created_at: (24.hours.ago)..(DateTime.now)).where_assoc_exists(:histories, &:user_enrolled_last_24h).count
      }
      results[title]['New today enrolled by API'] = {
        exposure: activity_exp.where(isolation: false, created_at: (24.hours.ago)..(DateTime.now)).where_assoc_exists(:histories, &:api_enrolled_last_24h).count,
        isolation: activity_iso.where(isolation: true, created_at: (24.hours.ago)..(DateTime.now)).where_assoc_exists(:histories, &:api_enrolled_last_24h).count
      }
      results[title]['Total with activity today (user)'] = {
        exposure: activity_exp.where(isolation: false).where_assoc_exists(:histories) { user_generated_since(24.hours.ago) }.count,
        isolation: activity_iso.where(isolation: true).where_assoc_exists(:histories) { user_generated_since(24.hours.ago) }.count
      }
      results[title]['Total with activity since start of evaluation (user)'] = {
        exposure: activity_exp.where(isolation: false).where_assoc_exists(:histories) { user_generated_since(start) }.count,
        isolation: activity_iso.where(isolation: true).where_assoc_exists(:histories) { user_generated_since(start) }.count
      }
      results[title]['Total with activity today (monitoree)'] = {
        exposure: activity_exp.where(isolation: false).where_assoc_exists(:assessments) { created_since(24.hours.ago) }.count,
        isolation: activity_iso.where(isolation: true).where_assoc_exists(:assessments) { created_since(24.hours.ago) }.count
      }
      results[title]['Total with activity since start of evaluation (monitoree)'] = {
        exposure: activity_exp.where(isolation: false).where_assoc_exists(:assessments) { monitoree_created_since(start) }.count,
        isolation: activity_iso.where(isolation: true).where_assoc_exists(:assessments) { monitoree_created_since(start) }.count
      }
      results[title]['Total with activity today (user & monitoree)'] = {
        exposure: (activity_exp.where(isolation: false).where_assoc_exists(:histories) { user_generated_since(24.hours.ago) }.pluck(:id) + activity_exp.where(isolation: false).where_assoc_exists(:assessments) { created_since(24.hours.ago) }.pluck(:id) ).uniq.count,
        isolation: (activity_iso.where(isolation: true).where_assoc_exists(:histories) { user_generated_since(24.hours.ago) }.pluck(:id) + activity_iso.where(isolation: true).where_assoc_exists(:assessments) { created_since(24.hours.ago) }.pluck(:id)).uniq.count
      }
      results[title]['Total with activity since start of evaluation (user & monitoree)'] = {
        exposure: (activity_exp.where(isolation: false).where_assoc_exists(:histories) { user_generated_since(start) }.pluck(:id) + activity_exp.where(isolation: false).where_assoc_exists(:assessments) { created_since(start) }.pluck(:id) ).uniq.count,
        isolation: (activity_iso.where(isolation: true).where_assoc_exists(:histories) { user_generated_since(start) }.pluck(:id) + activity_iso.where(isolation: true).where_assoc_exists(:assessments) { created_since(start) }.pluck(:id) ).uniq.count
      }
      results[title]['Closed today - Enrolled more than 14 days after last date of exposure (system)'] = {
        exposure: activity_exp.where(monitoring: false, monitoring_reason: 'Enrolled more than 14 days after last date of exposure (system)').where_assoc_exists(:histories, &:system_closed_last_24h).count,
        isolation: 'N/A'
      }
      results[title]['Closed today - Enrolled on last day of monitoring period (system)'] = {
        exposure: activity_exp.where(monitoring: false, monitoring_reason: 'Enrolled on last day of monitoring period (system)').where_assoc_exists(:histories, &:system_closed_last_24h).count,
        isolation: 'N/A'
      }
      results[title]['Closed today - Completed Monitoring (system)'] = {
        exposure: activity_exp.where(monitoring: false, monitoring_reason: 'Completed Monitoring (system)').where_assoc_exists(:histories, &:system_closed_last_24h).count,
        isolation: 'N/A'
      }
      results[title]['Closed today - manually'] = {
        exposure: activity_exp.where(isolation: false, monitoring: false).where_assoc_exists(:histories, &:user_closed_last_24h).count,
        isolation: activity_iso.where(isolation: true, monitoring: false).where_assoc_exists(:histories, &:user_closed_last_24h).count
      }

      puts 'Step 3 of 6: reporting rates'
      title = "REPORTING: Cohort of active monitorees existing or added during 14 day period EXCLUDING Opt-out or Unknown reporting methods"
      results[title] = {}
      active_exp = jur_patients.where(monitoring: true, isolation: false).where('patients.updated_at >= ?', start.to_time.beginning_of_day).where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
      active_iso = jur_patients.where(monitoring: true, isolation: true).where('patients.updated_at >= ?', start.to_time.beginning_of_day).where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
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
      results[title]['Total number of monitorees in the system < 21 days'] = {
        exposure: active_exp.where('created_at >= ?', 21.days.ago).count,
        isolation: active_iso.where('created_at >= ?', 21.days.ago).count
      }
      reporting_days_exp = []
      reporting_days_responded_to_all_exp = []
      responded_to_all_reminders_self_exp = 0
      responded_to_50_reminders_self_exp = 0
      responded_to_75_reminders_self_exp = 0
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
      emailed_rates_count_exp = 0
      sms_weblink_rates_count_exp = 0
      phone_rates_count_exp = 0
      sms_text_rates_count_exp = 0
      overall_rates_count_exp = 0
      enrollment_to_lde_exp = []
      enrollment_to_first_rep_exp = []
      activity_first_24h_exp = 0
      activity_first_48h_exp = 0
      active_exp.find_each do |patient|
        times_sent = patient.histories.reminder_sent_since(start).pluck(:created_at).collect { |ca| ca.to_date }.sort.uniq
        reporting_days_exp << times_sent.count
        times_recv_self = patient.assessments.created_since(start).created_by_monitoree.pluck(:created_at).collect { |ca| ca.to_date }.sort.uniq
        times_recv_self_and_user = patient.assessments.created_since(start).pluck(:created_at).collect { |ca| ca.to_date }.sort.uniq
        times_recv_user = patient.assessments.created_since(start).created_by_user.pluck(:created_at).collect { |ca| ca.to_date }.sort.uniq
        responded_to_all_reminders_self_exp += 1 if times_sent.count <= times_recv_self.count
        responded_to_50_reminders_self_exp += 1 if (times_sent.count * 0.50) <= times_recv_self.count
        responded_to_75_reminders_self_exp += 1 if (times_sent.count * 0.75) <= times_recv_self.count
        responded_to_all_reminders_self_and_user_exp += 1 if times_sent.count <= times_recv_self_and_user.count
        reporting_days_responded_to_all_exp << times_sent.count if times_sent.count <= times_recv_self_and_user.count
        not_respond_to_all_reminders_self_exp += 1 if times_sent.count > times_recv_self.count
        not_respond_to_all_reminders_self_and_user_exp += 1 if times_sent.count > times_recv_self_and_user.count
        days_no_response_self_exp << times_sent.count - times_recv_self.count if times_sent.count > times_recv_self.count
        days_no_response_self_and_user_exp << times_sent.count - times_recv_self_and_user.count if times_sent.count > times_recv_self_and_user.count
        if times_sent.count > times_recv_self.count
          all_cons = []
          last_cons = 0
          missed_times = (times_sent - times_recv_self)
          missed_times.each_cons(2) { |a, b| (b.mjd - a.mjd) == 1 ? last_cons += ( last_cons == 0 ? 2 : 1) : (all_cons << last_cons && last_cons = 0) }
          all_cons << (last_cons == 0 ? 1 : last_cons) unless missed_times.count == 0
          cons_days_no_response_self_exp << all_cons.inject{ |sum, el| sum + el }.to_f / all_cons.size unless all_cons.empty?
        end
        if times_sent.count > times_recv_self_and_user.count
          all_cons = []
          last_cons = 0
          missed_times = (times_sent - times_recv_self_and_user)
          missed_times.each_cons(2) { |a, b| (b.mjd - a.mjd) == 1 ? last_cons += ( last_cons == 0 ? 2 : 1) : (all_cons << last_cons && last_cons = 0) }
          all_cons << (last_cons == 0 ? 1 : last_cons) unless missed_times.count == 0
          cons_days_no_response_self_and_user_exp << all_cons.inject{ |sum, el| sum + el }.to_f / all_cons.size unless all_cons.empty?
        end
        emailed_rates_exp << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'E-mailed Web Link' && !times_sent.empty?
        sms_weblink_rates_exp << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'SMS Texted Weblink' && !times_sent.empty?
        phone_rates_exp << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'Telephone call' && !times_sent.empty?
        sms_text_rates_exp << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'SMS Text-message' && !times_sent.empty?
        overall_rates_exp << times_recv_self_and_user.count / times_sent.count.to_f if !times_sent.empty?
        unless patient.last_date_of_exposure.nil? || patient.continuous_exposure || patient.last_date_of_exposure > patient.created_at
          enrollment_to_lde_exp << (patient.created_at.to_date - patient.last_date_of_exposure.to_date).to_i
        end
        emailed_rates_count_exp += times_sent.count if patient.preferred_contact_method == 'E-mailed Web Link' && !times_sent.empty?
        sms_weblink_rates_count_exp += times_sent.count if patient.preferred_contact_method == 'SMS Texted Weblink' && !times_sent.empty?
        phone_rates_count_exp += times_sent.count if patient.preferred_contact_method == 'Telephone call' && !times_sent.empty?
        sms_text_rates_count_exp += times_sent.count if patient.preferred_contact_method == 'SMS Text-message' && !times_sent.empty?
        overall_rates_count_exp += times_sent.count if !times_sent.empty?
        enrollment_to_first_rep_exp << (times_recv_self_and_user.first - patient.created_at.to_date).to_i unless times_recv_self_and_user.empty?
        activity_first_24h_exp += 1 if patient.histories.user_generated_between(patient.created_at, patient.created_at + 24.hours).count.positive?
        activity_first_48h_exp += 1 if patient.histories.user_generated_between(patient.created_at, patient.created_at + 48.hours).count.positive?
      end
      reporting_days_iso = []
      reporting_days_responded_to_all_iso = []
      responded_to_all_reminders_self_iso = 0
      responded_to_50_reminders_self_iso = 0
      responded_to_75_reminders_self_iso = 0
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
      emailed_rates_count_iso = 0
      sms_weblink_rates_count_iso = 0
      phone_rates_count_iso = 0
      sms_text_rates_count_iso = 0
      overall_rates_count_iso = 0
      enrollment_to_first_rep_iso = []
      activity_first_24h_iso = 0
      activity_first_48h_iso = 0
      active_iso.find_each do |patient|
        times_sent = patient.histories.reminder_sent_since(start).pluck(:created_at).collect { |ca| ca.to_date }.sort.uniq
        reporting_days_iso << times_sent.count
        times_recv_self = patient.assessments.created_since(start).created_by_monitoree.pluck(:created_at).collect { |ca| ca.to_date }.sort.uniq
        times_recv_self_and_user = patient.assessments.created_since(start).pluck(:created_at).collect { |ca| ca.to_date }.sort.uniq
        times_recv_user = patient.assessments.created_since(start).created_by_user.pluck(:created_at).collect { |ca| ca.to_date }.sort.uniq
        responded_to_all_reminders_self_iso += 1 if times_sent.count <= times_recv_self.count
        responded_to_50_reminders_self_iso += 1 if (times_sent.count * 0.50) <= times_recv_self.count
        responded_to_75_reminders_self_iso += 1 if (times_sent.count * 0.75) <= times_recv_self.count
        responded_to_all_reminders_self_and_user_iso += 1 if times_sent.count <= times_recv_self_and_user.count
        reporting_days_responded_to_all_iso << times_sent.count if times_sent.count <= times_recv_self_and_user.count
        not_respond_to_all_reminders_self_iso += 1 if times_sent.count > times_recv_self.count
        not_respond_to_all_reminders_self_and_user_iso += 1 if times_sent.count > times_recv_self_and_user.count
        days_no_response_self_iso << times_sent.count - times_recv_self.count if times_sent.count > times_recv_self.count
        days_no_response_self_and_user_iso << times_sent.count - times_recv_self_and_user.count if times_sent.count > times_recv_self_and_user.count
        if times_sent.count > times_recv_self.count
          all_cons = []
          last_cons = 0
          missed_times = (times_sent - times_recv_self)
          missed_times.each_cons(2) { |a, b| (b.mjd - a.mjd) == 1 ? last_cons += ( last_cons == 0 ? 2 : 1) : (all_cons << last_cons && last_cons = 0) }
          all_cons << (last_cons == 0 ? 1 : last_cons) unless missed_times.count == 0
          cons_days_no_response_self_iso << all_cons.inject{ |sum, el| sum + el }.to_f / all_cons.size unless all_cons.empty?
        end
        if times_sent.count > times_recv_self_and_user.count
          all_cons = []
          last_cons = 0
          missed_times = (times_sent - times_recv_self_and_user)
          missed_times.each_cons(2) { |a, b| (b.mjd - a.mjd) == 1 ? last_cons += ( last_cons == 0 ? 2 : 1) : (all_cons << last_cons && last_cons = 0) }
          all_cons << (last_cons == 0 ? 1 : last_cons) unless missed_times.count == 0
          cons_days_no_response_self_and_user_iso << all_cons.inject{ |sum, el| sum + el }.to_f / all_cons.size unless all_cons.empty?
        end
        emailed_rates_iso << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'E-mailed Web Link' && !times_sent.empty?
        sms_weblink_rates_iso << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'SMS Texted Weblink' && !times_sent.empty?
        phone_rates_iso << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'Telephone call' && !times_sent.empty?
        sms_text_rates_iso << times_recv_self_and_user.count / times_sent.count.to_f if patient.preferred_contact_method == 'SMS Text-message' && !times_sent.empty?
        overall_rates_iso << times_recv_self_and_user.count / times_sent.count.to_f if !times_sent.empty?
        emailed_rates_count_iso += times_sent.count if patient.preferred_contact_method == 'E-mailed Web Link' && !times_sent.empty?
        sms_weblink_rates_count_iso += times_sent.count if patient.preferred_contact_method == 'SMS Texted Weblink' && !times_sent.empty?
        phone_rates_count_iso += times_sent.count if patient.preferred_contact_method == 'Telephone call' && !times_sent.empty?
        sms_text_rates_count_iso += times_sent.count if patient.preferred_contact_method == 'SMS Text-message' && !times_sent.empty?
        overall_rates_count_iso += times_sent.count if !times_sent.empty?
        enrollment_to_first_rep_iso << (times_recv_self_and_user.first - patient.created_at.to_date).to_i unless times_recv_self_and_user.empty?
        activity_first_24h_iso += 1 if patient.histories.user_generated_between(patient.created_at, patient.created_at + 24.hours).count.positive?
        activity_first_48h_iso += 1 if patient.histories.user_generated_between(patient.created_at, patient.created_at + 48.hours).count.positive?
      end
      results[title]['Mean number of reporting days'] = {
        exposure: reporting_days_exp.empty? ? 0 : reporting_days_exp.inject{ |sum, el| sum + el }.to_f / reporting_days_exp.size,
        isolation: reporting_days_iso.empty? ? 0 : reporting_days_iso.inject{ |sum, el| sum + el }.to_f / reporting_days_iso.size,
      }
      results[title]['Mean number of reporting days for those responding to all'] = {
        exposure: reporting_days_responded_to_all_exp.empty? ? 0 : reporting_days_responded_to_all_exp.inject{ |sum, el| sum + el }.to_f / reporting_days_responded_to_all_exp.size,
        isolation: reporting_days_responded_to_all_iso.empty? ? 0 : reporting_days_responded_to_all_iso.inject{ |sum, el| sum + el }.to_f / reporting_days_responded_to_all_iso.size,
      }
      results[title]['Number of monitorees responding to ALL automated messages (monitoree or proxy response only)'] = {
        exposure: responded_to_all_reminders_self_exp,
        isolation: responded_to_all_reminders_self_iso
      }
      results[title]['Number of monitorees responding to at least 50% of messages (monitoree or proxy response only)'] = {
        exposure: responded_to_50_reminders_self_exp,
        isolation: responded_to_50_reminders_self_iso
      }
      results[title]['Number of monitorees responding to at least 75% of messages (monitoree or proxy response only)'] = {
        exposure: responded_to_75_reminders_self_exp,
        isolation: responded_to_75_reminders_self_iso
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
        exposure: days_no_response_self_exp.empty? ? 0 : days_no_response_self_exp.inject{ |sum, el| sum + el }.to_f / days_no_response_self_exp.size,
        isolation: days_no_response_self_iso.empty? ? 0 : days_no_response_self_iso.inject{ |sum, el| sum + el }.to_f / days_no_response_self_iso.size
      }
      results[title]['Number of Monitorees who DID NOT RESPOND to all daily automated messages (monitoree or proxy response only) - Mean number of consecutive days with no response'] = {
        exposure: cons_days_no_response_self_exp.empty? ? 0 : cons_days_no_response_self_exp.inject{ |sum, el| sum + el }.to_f / cons_days_no_response_self_exp.size,
        isolation: cons_days_no_response_self_iso.empty? ? 0 : cons_days_no_response_self_iso.inject{ |sum, el| sum + el }.to_f / cons_days_no_response_self_iso.size
      }
      results[title]['Number of Monitorees who DID NOT RESPOND to all automated messages (any response documented, including by public health user)'] = {
        exposure: not_respond_to_all_reminders_self_and_user_exp,
        isolation: not_respond_to_all_reminders_self_and_user_iso
      }
      results[title]['Number of Monitorees who DID NOT RESPOND to all automated messages (any response documented, including by public health user) - Mean number of days with no response'] = {
        exposure: days_no_response_self_and_user_exp.empty? ? 0 : days_no_response_self_and_user_exp.inject{ |sum, el| sum + el }.to_f / days_no_response_self_and_user_exp.size,
        isolation: days_no_response_self_and_user_iso.empty? ? 0 : days_no_response_self_and_user_iso.inject{ |sum, el| sum + el }.to_f / days_no_response_self_and_user_iso.size
      }
      results[title]['Number of Monitorees who DID NOT RESPOND to all automated messages (any response documented, including by public health user) - Mean number of consecutive days with no response'] = {
        exposure: cons_days_no_response_self_and_user_exp.empty? ? 0 : cons_days_no_response_self_and_user_exp.inject{ |sum, el| sum + el }.to_f / cons_days_no_response_self_and_user_exp.size,
        isolation: cons_days_no_response_self_and_user_iso.empty? ? 0 : cons_days_no_response_self_and_user_iso.inject{ |sum, el| sum + el }.to_f / cons_days_no_response_self_and_user_iso.size
      }
      results[title]['Monitoree Response Rate - E-mailed Web Link'] = {
        exposure: emailed_rates_exp.empty? ? 0 : emailed_rates_exp.inject{ |sum, el| sum + el }.to_f / emailed_rates_exp.size,
        isolation: emailed_rates_iso.empty? ? 0 : emailed_rates_iso.inject{ |sum, el| sum + el }.to_f / emailed_rates_iso.size
      }
      results[title]['Monitoree Response Rate - SMS Texted Weblink'] = {
        exposure: sms_weblink_rates_exp.empty? ? 0 : sms_weblink_rates_exp.inject{ |sum, el| sum + el }.to_f / sms_weblink_rates_exp.size,
        isolation: sms_weblink_rates_iso.empty? ? 0 : sms_weblink_rates_iso.inject{ |sum, el| sum + el }.to_f / sms_weblink_rates_iso.size
      }
      results[title]['Monitoree Response Rate - Telephone call'] = {
        exposure: phone_rates_exp.empty? ? 0 : phone_rates_exp.inject{ |sum, el| sum + el }.to_f / phone_rates_exp.size,
        isolation: phone_rates_iso.empty? ? 0 : phone_rates_iso.inject{ |sum, el| sum + el }.to_f / phone_rates_iso.size
      }
      results[title]['Monitoree Response Rate - SMS Text-message'] = {
        exposure: sms_text_rates_exp.empty? ? 0 : sms_text_rates_exp.inject{ |sum, el| sum + el }.to_f / sms_text_rates_exp.size,
        isolation: sms_text_rates_iso.empty? ? 0 : sms_text_rates_iso.inject{ |sum, el| sum + el }.to_f / sms_text_rates_iso.size
      }
      results[title]['Monitoree Response Rate - Overall'] = {
        exposure: overall_rates_exp.empty? ? 0 : overall_rates_exp.inject{ |sum, el| sum + el }.to_f / overall_rates_exp.size,
        isolation: overall_rates_iso.empty? ? 0 : overall_rates_iso.inject{ |sum, el| sum + el }.to_f / overall_rates_iso.size
      }
      results[title]['Monitoree Total Sent Message Count - E-mailed Web Link'] = {
        exposure: emailed_rates_count_exp,
        isolation: emailed_rates_count_iso
      }
      results[title]['Monitoree Total Sent Message Count - SMS Texted Weblink'] = {
        exposure: sms_weblink_rates_count_exp,
        isolation: sms_weblink_rates_count_iso
      }
      results[title]['Monitoree Total Sent Message Count - Telephone call'] = {
        exposure: phone_rates_count_exp,
        isolation: phone_rates_count_iso
      }
      results[title]['Monitoree Total Sent Message Count - SMS Text-message'] = {
        exposure: sms_text_rates_count_exp,
        isolation: sms_text_rates_count_iso
      }
      results[title]['Monitoree Total Sent Message Count - Overall'] = {
        exposure: overall_rates_count_exp,
        isolation: overall_rates_count_iso
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
        exposure: enrollment_to_lde_exp.empty? ? 0 : enrollment_to_lde_exp.inject{ |sum, el| sum + el }.to_f / enrollment_to_lde_exp.size,
        isolation: 'N/A'
      }
      results[title]['Time between create date and first report by monitoree'] = {
        exposure: enrollment_to_first_rep_exp.empty? ? 0 : enrollment_to_first_rep_exp.inject{ |sum, el| sum + el }.to_f / enrollment_to_first_rep_exp.size,
        isolation: enrollment_to_first_rep_iso.empty? ? 0 : enrollment_to_first_rep_iso.inject{ |sum, el| sum + el }.to_f / enrollment_to_first_rep_iso.size
      }
      results[title]['Number of monitorees with any action other than none in their history'] = {
        exposure: active_exp.where_assoc_exists(:histories) { user_generated_since(start) }.count,
        isolation: active_iso.where_assoc_exists(:histories) { user_generated_since(start) }.count
      }
      results[title]['Number of monitorees with any user-generated activity in their history after the first 24 hours'] = {
        exposure: activity_first_24h_exp,
        isolation: activity_first_24h_iso
      }
      results[title]['Number of monitorees with any user-generated activity in their history after the first 48 hours'] = {
        exposure: activity_first_48h_exp,
        isolation: activity_first_48h_iso
      }
      results[title]['Number of monitorees in continuous exposure'] = {
        exposure: active_exp.where(continuous_exposure: true).count,
        isolation: 'N/A'
      }

      puts 'Step 4 of 6: demographics'
      title = "DEMOGRAPHICS: Cohort of active monitorees existing or added during 14 day period EXCLUDING Opt-out or Unknown reporting methods"
      results[title] = {}
      active_exp = jur_patients.where(monitoring: true, isolation: false).where('patients.updated_at >= ?', start.to_time.beginning_of_day).where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
      active_iso = jur_patients.where(monitoring: true, isolation: true).where('patients.updated_at >= ?', start.to_time.beginning_of_day).where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
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
      results[title]['Race - Other indicated'] = {
        exposure: active_exp.where(race_other: true).count,
        isolation: active_iso.where(race_other: true).count
      }
      results[title]['Race - Unknown indicated'] = {
        exposure: active_exp.where(race_unknown: true).count,
        isolation: active_iso.where(race_unknown: true).count
      }
      results[title]['Race - Refused to answer indicated'] = {
        exposure: active_exp.where(race_refused_to_answer: true).count,
        isolation: active_iso.where(race_refused_to_answer: true).count
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
        exposure: active_exp.where(sex: ['', nil], ethnicity: ['', nil], race_other: [false, nil], race_unknown: [false, nil], race_refused_to_answer: [false, nil], white: [false, nil], black_or_african_american: [false, nil], american_indian_or_alaska_native: [false, nil], asian: [false, nil], native_hawaiian_or_other_pacific_islander: [false, nil]).count,
        isolation: active_iso.where(sex: ['', nil], ethnicity: ['', nil], race_other: [false, nil], race_unknown: [false, nil], race_refused_to_answer: [false, nil], white: [false, nil], black_or_african_american: [false, nil], american_indian_or_alaska_native: [false, nil], asian: [false, nil], native_hawaiian_or_other_pacific_islander: [false, nil]).count
      }
      results[title]['Age - <= 5'] = {
        exposure: active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 6').count,
        isolation: active_iso.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 6').count
      }
      results[title]['Age - 6-11'] = {
        exposure: active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 6').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 12').count,
        isolation: active_iso.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 6').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 12').count
      }
      results[title]['Age - 12-18'] = {
        exposure: active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 12').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 19').count,
        isolation: active_iso.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 12').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 19').count
      }
      results[title]['Age - <= 18'] = {
        exposure: active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 19').count,
        isolation: active_iso.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 19').count
      }
      results[title]['Age - 19-29'] = {
        exposure: active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 19').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 30').count,
        isolation: active_iso.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 19').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 30').count
      }
      results[title]['Age - 30-39'] = {
        exposure: active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 30').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 40').count,
        isolation: active_iso.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 30').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 40').count
      }
      results[title]['Age - 40-49'] = {
        exposure: active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 40').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 50').count,
        isolation: active_iso.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 40').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 50').count
      }
      results[title]['Age - 50-59'] = {
        exposure: active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 50').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 60').count,
        isolation: active_iso.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 50').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 60').count
      }
      results[title]['Age - 60-69'] = {
        exposure: active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 60').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 70').count,
        isolation: active_iso.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 60').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 70').count
      }
      results[title]['Age - 70-79'] = {
        exposure: active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 70').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 80').count,
        isolation: active_iso.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 70').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 80').count
      }
      results[title]['Age - >= 80'] = {
        exposure: active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 80').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 110').count,
        isolation: active_iso.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 80').where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 110').count
      }
      results[title]['Age - Flagged for possible missing age'] = {
        exposure: active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 110').or(active_exp.where(date_of_birth: ['', nil])).count,
        isolation: active_iso.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) >= 110').or(active_exp.where(date_of_birth: ['', nil])).count
      }
      begin
        dates_exp = active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 110').pluck(:date_of_birth).reject(&:nil?).collect{|dob| dob.to_datetime.to_f}
        dates_iso = active_exp.where('TIMESTAMPDIFF(YEAR, date_of_birth, created_at) < 110').pluck(:date_of_birth).reject(&:nil?).collect{|dob| dob.to_datetime.to_f}
        results[title]['Age - Continuous mean'] = {
          exposure: dates_exp.empty? ? 'NULL' : (DateTime.now.year - Date.strptime((dates_exp.sum / dates_exp.count).to_i.to_s, "%s").year),
          isolation: dates_iso.empty? ? 'NULL' : (DateTime.now.year - Date.strptime((dates_iso.sum / dates_iso.count).to_i.to_s, "%s").year)
        }
      rescue StandardError => error
        results[title]['Age - Continuous mean'] = {
          exposure: 'NULL',
          isolation: 'NULL'
        }
      end
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
        exposure: active_exp.where(primary_language: 'eng').count,
        isolation: active_iso.where(primary_language: 'eng').count
      }
      results[title]['Preferred Language - Spanish'] = {
        exposure: active_exp.where(primary_language: 'spa').count,
        isolation: active_iso.where(primary_language: 'spa').count
      }
      results[title]['Preferred Language - Spanish (Puerto Rican)'] = {
        exposure: active_exp.where(primary_language: 'spa-pr').count,
        isolation: active_iso.where(primary_language: 'spa-pr').count
      }
      results[title]['Preferred Language - French'] = {
        exposure: active_exp.where(primary_language: 'fra').count,
        isolation: active_iso.where(primary_language: 'fra').count
      }
      results[title]['Preferred Language - Somali'] = {
        exposure: active_exp.where(primary_language: 'som').count,
        isolation: active_iso.where(primary_language: 'som').count
      }
      results[title]['Preferred Language - Korean'] = {
        exposure: active_exp.where(primary_language: 'kor').count,
        isolation: active_iso.where(primary_language: 'kor').count
      }
      results[title]['Preferred Language - Vietnamese'] = {
        exposure: active_exp.where(primary_language: 'vie').count,
        isolation: active_iso.where(primary_language: 'vie').count
      }
      results[title]['Preferred Language - Russian'] = {
        exposure: active_exp.where(primary_language: 'rus').count,
        isolation: active_iso.where(primary_language: 'rus').count
      }
      # results[title]['Preferred Language - Arabic'] = {
      #   exposure: active_exp.where(primary_language: 'ara').count,
      #   isolation: active_iso.where(primary_language: 'ara').count
      # }
      results[title]['Preferred Language - Chinese'] = {
        exposure: active_exp.where(primary_language: 'zho').count,
        isolation: active_iso.where(primary_language: 'zho').count
      }
      results[title]['Preferred Language - Other'] = {
        exposure: active_exp.where.not(primary_language: ['', nil, 'eng', 'spa', 'spa-pr', 'fra', 'som', 'kor', 'vie', 'rus', 'ara', 'zho']).count,
        isolation: active_iso.where.not(primary_language: ['', nil, 'eng', 'spa', 'spa-pr', 'fra', 'som', 'kor', 'vie', 'rus', 'ara', 'zho']).count
      }
      results[title]['Preferred Language - blank'] = {
        exposure: active_exp.where(primary_language: ['', nil]).count,
        isolation: active_iso.where(primary_language: ['', nil]).count
      }

      puts 'Step 5 of 6: user snapshots'
      title = 'USERS: Daily snapshots'
      results[title] = {}
      results[title]['Total'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where.not(role: [nil, '', 'none']).count, isolation: nil }
      results[title]['Unlocked'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(locked_at: nil).where.not(role: [nil, '', 'none']).count, isolation: nil }
      results[title]['Logged in last 7 days'] = { exposure: jur.all_users.where('current_sign_in_at >= ?', 7.days.ago).count, isolation: nil }
      results[title]['Super User'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'super_user').count, isolation: nil }
      results[title]['Public Health Enroller'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'public_health_enroller').count, isolation: nil }
      results[title]['Contact Tracer'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'contact_tracer').count, isolation: nil }
      results[title]['Public Health'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'public_health').count, isolation: nil }
      results[title]['Enroller'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'enroller').count, isolation: nil }
      results[title]['Analyst'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'analyst').count, isolation: nil }
      results[title]['Admins'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'admin').count, isolation: nil }
      results[title]['Super User (logged in last 7 days)'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'super_user').where('current_sign_in_at >= ?', 7.days.ago).count, isolation: nil }
      results[title]['Public Health Enroller (logged in last 7 days)'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'public_health_enroller').where('current_sign_in_at >= ?', 7.days.ago).count, isolation: nil }
      results[title]['Contact Tracer (logged in last 7 days)'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'contact_tracer').where('current_sign_in_at >= ?', 7.days.ago).count, isolation: nil }
      results[title]['Public Health (logged in last 7 days)'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'public_health').where('current_sign_in_at >= ?', 7.days.ago).count, isolation: nil }
      results[title]['Enroller (logged in last 7 days)'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'enroller').where('current_sign_in_at >= ?', 7.days.ago).count, isolation: nil }
      results[title]['Analyst (logged in last 7 days)'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'analyst').where('current_sign_in_at >= ?', 7.days.ago).count, isolation: nil }
      results[title]['Admins (logged in last 7 days)'] = { exposure: jur.all_users.where.not(jurisdiction_id: exclude_ids).where(role: 'admin').where('current_sign_in_at >= ?', 7.days.ago).count, isolation: nil }

      puts 'Step 6 of 6: finish'
      json = {}
      json[today] = results
      puts JSON.pretty_generate(json, { allow_nan: true })
      Stat.create!(contents: json.to_json, jurisdiction_id: jur.id, tag: tag)
    end
    UserMailer.stats_eval_email(ids).deliver_later
  end

  task eval_queries_export: :environment do
    ids = ENV['ids']&.split(',')&.collect { |id| id.to_i }

    raise 'You must provide at least one id (e.g. ids=1,2,3)' if ids.nil? || ids.empty?

    raise 'No stats found for those ids, are you sure you have specified a valid id?' unless Stat.where(jurisdiction_id: ids).exists?

    tag = ENV['tag']

    raise 'You must provide a tag (e.g. tag=blah)' if tag.nil?

    raise 'No stats found for that tag, are you sure you have specified a valid tag?' unless Stat.where(tag: tag).exists?

    jurisdictions = Jurisdiction.where(id: ids)
    package = Axlsx::Package.new
    workbook = package.workbook
    styles = workbook.styles
    header = styles.add_style sz: 14, b: true, alignment: { horizontal: :center }
    subheader = styles.add_style sz: 12, b: true, alignment: { horizontal: :center }
    jurisdictions.each do |jur|
      stats = Stat.where(jurisdiction_id: jur.id, tag: tag)
      contents = stats.collect { |s| JSON.parse(s.contents).values.first }
      days = stats.collect { |s| JSON.parse(s.contents).keys.first }
      structure = {}; contents.first.keys.each { |k| structure[k] = contents.first[k].keys }
      rows = []
      structure.keys.each do |h|
        rows << [h]
        structure[h].each do |sh|
          vals = []
          contents.each do |content|
            vals << content[h][sh].values
          end
          rows << (['    ' + sh] + vals).flatten
        end
        rows << [' ']
      end
      workbook.add_worksheet(name: "#{jur.name}") do |sheet|
        sheet.add_row([''] + days.collect { |d| [d, ''] }.flatten, style: header)
        sheet.add_row([''] + (['Exposure', 'Isolation'] * days.count), style: subheader)
        rows.each { |row| sheet.add_row row }
      end
    end

    package.serialize 'eval_queries.xlsx'
  end

  task all_time_twilio_stats: :environment do
    twilio_stats_since_date(Date.new(2020,3,1))
  end

  task month_twilio_stats: :environment do
    twilio_stats_since_date(1.month.ago.to_date)
  end

  def twilio_stat(category, since_date, client=nil)
    client = Twilio::REST::Client.new(ENV['TWILLIO_API_ACCOUNT'], ENV['TWILLIO_API_KEY']) if client.nil?
    record = (client.usage.records.list(category: category, start_date: since_date).collect do |record| record end)[0]
    entry = "#{record&.count&.reverse&.gsub(/...(?=.)/,'\&,')&.reverse} | " unless record&.count.nil?
    "#{entry}$#{record.price&.to_i&.to_s&.reverse&.gsub(/...(?=.)/,'\&,')&.reverse}"
  end

  def twilio_stats_since_date(since_date)
    client = Twilio::REST::Client.new(ENV['TWILLIO_API_ACCOUNT'], ENV['TWILLIO_API_KEY'])
    puts "Twilio Stats Since #{since_date.to_s}"
    puts "Total Price: #{twilio_stat('totalprice', since_date, client)}"
    puts "SMS Total: #{twilio_stat('sms', since_date, client)}"
    puts "\t SMS Inbound: #{twilio_stat('sms-inbound', since_date, client)}"
    puts "\t SMS Outound: #{twilio_stat('sms-outbound', since_date, client)}"
    puts "Calls Total: #{twilio_stat('calls', since_date, client)}"
    puts "\t Calls Inbound: #{twilio_stat('calls-inbound', since_date, client)}"
    puts "\t Calls Outound: #{twilio_stat('calls-outbound', since_date, client)}"
    puts "Authy Authentications: #{twilio_stat('authy-authentications', since_date, client)}"
    puts "\t Authy Calls: #{twilio_stat('authy-calls-outbound', since_date, client)}"
    puts "\t Authy SMS: #{twilio_stat('authy-sms-outbound', since_date, client)}"
    puts "\t Authy Emails: #{twilio_stat('authy-outbound-email', since_date, client)}"
  end

end
