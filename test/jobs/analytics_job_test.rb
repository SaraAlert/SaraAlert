# frozen_string_literal: true

require 'test_case'

class AnalyticsJobTest < ActiveSupport::TestCase
  fixtures :all
  @@monitorees = Patient.where('jurisdiction_id >= ?', 1).where('jurisdiction_id <= ?', 7)
  @@monitorees_by_exposure_week = Patient.where(jurisdiction_id: 8)
  @@monitorees_by_exposure_month = Patient.where(jurisdiction_id: 9)

  def setup
    ADMIN_OPTIONS['job_run_email'] = 'test@test.com'
  end

  def teardown
    ADMIN_OPTIONS['job_run_email'] = nil
  end

  test 'cache analytics job' do
    Analytic.delete_all
    MonitoreeCount.delete_all
    MonitoreeSnapshot.delete_all
    CacheAnalyticsJob.perform_now

    assert_equal(10, Analytic.all.size)

    assert_equal(55, MonitoreeCount.where(category_type: 'Overall Total').size)
    assert_equal(25, MonitoreeCount.where(category_type: 'Monitoring Status').size)
    assert_equal(112, MonitoreeCount.where(category_type: 'Age Group').size)
    assert_equal(96, MonitoreeCount.where(category_type: 'Sex').size)
    assert_equal(53, MonitoreeCount.where(category_type: 'Risk Factor').size)
    assert_equal(29, MonitoreeCount.where(category_type: 'Exposure Country').size)
    assert_not_equal(0, MonitoreeCount.where(category_type: 'Last Exposure Date').size)
    assert_not_equal(0, MonitoreeCount.where(category_type: 'Last Exposure Week').size)
    assert_not_equal(0, MonitoreeCount.where(category_type: 'Last Exposure Month').size)
    assert_not_equal(0, MonitoreeCount.all.size)

    assert_equal(10, MonitoreeSnapshot.where(time_frame: 'Last 24 Hours').size)
    assert_equal(10, MonitoreeSnapshot.where(time_frame: 'Last 14 Days').size)
    assert_equal(10, MonitoreeSnapshot.where(time_frame: 'Total').size)
    assert_equal(30, MonitoreeSnapshot.all.size)

    assert_equal(31, MonitoreeMap.where(level: 'State', workflow: 'Exposure').size)
    assert_equal(11, MonitoreeMap.where(level: 'State', workflow: 'Isolation').size)
    assert_equal(29, MonitoreeMap.where(level: 'County', workflow: 'Exposure').size)
    assert_equal(7, MonitoreeMap.where(level: 'County', workflow: 'Isolation').size)
    assert_equal(78, MonitoreeMap.all.size)
  end

  test 'all monitoree counts' do
    counts = CacheAnalyticsJob.all_monitoree_counts(1, @@monitorees)
    assert_not_equal(0, counts.length)
  end

  test 'monitoree counts by total' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_total(1, @@monitorees, true)
    verify_monitoree_count(active_counts, 0, true, 'Overall Total', 'Total', 'Missing', 18)
    verify_monitoree_count(active_counts, 1, true, 'Overall Total', 'Total', 'High', 3)
    verify_monitoree_count(active_counts, 2, true, 'Overall Total', 'Total', 'Low', 2)
    verify_monitoree_count(active_counts, 3, true, 'Overall Total', 'Total', 'Medium', 4)
    verify_monitoree_count(active_counts, 4, true, 'Overall Total', 'Total', 'No Identified Risk', 4)
    assert_equal(5, active_counts.length)

    overall_counts = CacheAnalyticsJob.monitoree_counts_by_total(1, @@monitorees, false)
    verify_monitoree_count(overall_counts, 0, false, 'Overall Total', 'Total', 'Missing', 18)
    verify_monitoree_count(overall_counts, 1, false, 'Overall Total', 'Total', 'High', 3)
    verify_monitoree_count(overall_counts, 2, false, 'Overall Total', 'Total', 'Low', 4)
    verify_monitoree_count(overall_counts, 3, false, 'Overall Total', 'Total', 'Medium', 5)
    verify_monitoree_count(overall_counts, 4, false, 'Overall Total', 'Total', 'No Identified Risk', 4)
    assert_equal(5, overall_counts.length)
  end

  test 'monitoree counts by monitoring status' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_monitoring_status(1, @@monitorees)
    verify_monitoree_count(active_counts, 0, true, 'Monitoring Status', 'Symptomatic', 'Missing', 3)
    verify_monitoree_count(active_counts, 1, true, 'Monitoring Status', 'Non-Reporting', 'Missing', 13)
    verify_monitoree_count(active_counts, 2, true, 'Monitoring Status', 'Asymptomatic', 'Missing', 2)
    assert_equal(3, active_counts.length)
  end

  test 'monitoree counts by age group' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_age_group(1, @@monitorees, true)
    verify_monitoree_count(active_counts, 0, true, 'Age Group', '0-19', 'Missing', 3)
    verify_monitoree_count(active_counts, 1, true, 'Age Group', '0-19', 'High', 1)
    verify_monitoree_count(active_counts, 2, true, 'Age Group', '0-19', 'Low', 1)
    verify_monitoree_count(active_counts, 3, true, 'Age Group', '0-19', 'Medium', 2)
    verify_monitoree_count(active_counts, 4, true, 'Age Group', '0-19', 'No Identified Risk', 2)
    verify_monitoree_count(active_counts, 5, true, 'Age Group', '20-29', 'Missing', 4)
    verify_monitoree_count(active_counts, 6, true, 'Age Group', '30-39', 'Missing', 4)
    verify_monitoree_count(active_counts, 7, true, 'Age Group', '30-39', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 8, true, 'Age Group', '40-49', 'Missing', 3)
    verify_monitoree_count(active_counts, 9, true, 'Age Group', '40-49', 'High', 1)
    verify_monitoree_count(active_counts, 10, true, 'Age Group', '40-49', 'Low', 1)
    verify_monitoree_count(active_counts, 11, true, 'Age Group', '40-49', 'Medium', 1)
    verify_monitoree_count(active_counts, 12, true, 'Age Group', '50-59', 'Missing', 1)
    verify_monitoree_count(active_counts, 13, true, 'Age Group', '50-59', 'High', 1)
    verify_monitoree_count(active_counts, 14, true, 'Age Group', '60-69', 'Missing', 2)
    verify_monitoree_count(active_counts, 15, true, 'Age Group', '60-69', 'Medium', 1)
    verify_monitoree_count(active_counts, 16, true, 'Age Group', '70-79', 'Missing', 1)
    verify_monitoree_count(active_counts, 17, true, 'Age Group', '>=80', 'No Identified Risk', 1)
    assert_equal(18, active_counts.length)

    overall_counts = CacheAnalyticsJob.monitoree_counts_by_age_group(1, @@monitorees, false)
    verify_monitoree_count(overall_counts, 0, false, 'Age Group', '0-19', 'Missing', 3)
    verify_monitoree_count(overall_counts, 1, false, 'Age Group', '0-19', 'High', 1)
    verify_monitoree_count(overall_counts, 2, false, 'Age Group', '0-19', 'Low', 1)
    verify_monitoree_count(overall_counts, 3, false, 'Age Group', '0-19', 'Medium', 3)
    verify_monitoree_count(overall_counts, 4, false, 'Age Group', '0-19', 'No Identified Risk', 2)
    verify_monitoree_count(overall_counts, 5, false, 'Age Group', '20-29', 'Missing', 4)
    verify_monitoree_count(overall_counts, 6, false, 'Age Group', '30-39', 'Missing', 4)
    verify_monitoree_count(overall_counts, 7, false, 'Age Group', '30-39', 'Low', 1)
    verify_monitoree_count(overall_counts, 8, false, 'Age Group', '30-39', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 9, false, 'Age Group', '40-49', 'Missing', 3)
    verify_monitoree_count(overall_counts, 10, false, 'Age Group', '40-49', 'High', 1)
    verify_monitoree_count(overall_counts, 11, false, 'Age Group', '40-49', 'Low', 1)
    verify_monitoree_count(overall_counts, 12, false, 'Age Group', '40-49', 'Medium', 1)
    verify_monitoree_count(overall_counts, 13, false, 'Age Group', '50-59', 'Missing', 1)
    verify_monitoree_count(overall_counts, 14, false, 'Age Group', '50-59', 'High', 1)
    verify_monitoree_count(overall_counts, 15, false, 'Age Group', '60-69', 'Missing', 2)
    verify_monitoree_count(overall_counts, 16, false, 'Age Group', '60-69', 'Low', 1)
    verify_monitoree_count(overall_counts, 17, false, 'Age Group', '60-69', 'Medium', 1)
    verify_monitoree_count(overall_counts, 18, false, 'Age Group', '70-79', 'Missing', 1)
    verify_monitoree_count(overall_counts, 19, false, 'Age Group', '>=80', 'No Identified Risk', 1)
    assert_equal(20, overall_counts.length)
  end

  test 'monitoree counts by sex' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_sex(1, @@monitorees, true)
    verify_monitoree_count(active_counts, 0, true, 'Sex', 'Missing', 'Medium', 1)
    verify_monitoree_count(active_counts, 1, true, 'Sex', 'Missing', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 2, true, 'Sex', 'Female', 'Missing', 8)
    verify_monitoree_count(active_counts, 3, true, 'Sex', 'Female', 'High', 1)
    verify_monitoree_count(active_counts, 4, true, 'Sex', 'Female', 'Low', 1)
    verify_monitoree_count(active_counts, 5, true, 'Sex', 'Female', 'Medium', 1)
    verify_monitoree_count(active_counts, 6, true, 'Sex', 'Female', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 7, true, 'Sex', 'Male', 'Missing', 8)
    verify_monitoree_count(active_counts, 8, true, 'Sex', 'Male', 'High', 1)
    verify_monitoree_count(active_counts, 9, true, 'Sex', 'Male', 'Low', 1)
    verify_monitoree_count(active_counts, 10, true, 'Sex', 'Male', 'Medium', 1)
    verify_monitoree_count(active_counts, 11, true, 'Sex', 'Male', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 12, true, 'Sex', 'Unknown', 'Missing', 2)
    verify_monitoree_count(active_counts, 13, true, 'Sex', 'Unknown', 'High', 1)
    verify_monitoree_count(active_counts, 14, true, 'Sex', 'Unknown', 'Medium', 1)
    verify_monitoree_count(active_counts, 15, true, 'Sex', 'Unknown', 'No Identified Risk', 1)
    assert_equal(16, active_counts.length)

    overall_counts = CacheAnalyticsJob.monitoree_counts_by_sex(1, @@monitorees, false)
    verify_monitoree_count(overall_counts, 0, false, 'Sex', 'Missing', 'Medium', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Sex', 'Missing', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 2, false, 'Sex', 'Female', 'Missing', 8)
    verify_monitoree_count(overall_counts, 3, false, 'Sex', 'Female', 'High', 1)
    verify_monitoree_count(overall_counts, 4, false, 'Sex', 'Female', 'Low', 2)
    verify_monitoree_count(overall_counts, 5, false, 'Sex', 'Female', 'Medium', 1)
    verify_monitoree_count(overall_counts, 6, false, 'Sex', 'Female', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 7, false, 'Sex', 'Male', 'Missing', 8)
    verify_monitoree_count(overall_counts, 8, false, 'Sex', 'Male', 'High', 1)
    verify_monitoree_count(overall_counts, 9, false, 'Sex', 'Male', 'Low', 1)
    verify_monitoree_count(overall_counts, 10, false, 'Sex', 'Male', 'Medium', 1)
    verify_monitoree_count(overall_counts, 11, false, 'Sex', 'Male', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 12, false, 'Sex', 'Unknown', 'Missing', 2)
    verify_monitoree_count(overall_counts, 13, false, 'Sex', 'Unknown', 'High', 1)
    verify_monitoree_count(overall_counts, 14, false, 'Sex', 'Unknown', 'Low', 1)
    verify_monitoree_count(overall_counts, 15, false, 'Sex', 'Unknown', 'Medium', 2)
    verify_monitoree_count(overall_counts, 16, false, 'Sex', 'Unknown', 'No Identified Risk', 1)
    assert_equal(17, overall_counts.length)
  end

  test 'monitoree counts by risk factor' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_risk_factor(1, @@monitorees, true)
    verify_monitoree_count(active_counts, 0, true, 'Risk Factor', 'Close Contact with Known Case', 'High', 1)
    verify_monitoree_count(active_counts, 1, true, 'Risk Factor', 'Close Contact with Known Case', 'Medium', 1)
    verify_monitoree_count(active_counts, 2, true, 'Risk Factor', 'Travel from Affected Country or Area', 'Missing', 1)
    verify_monitoree_count(active_counts, 3, true, 'Risk Factor', 'Travel from Affected Country or Area', 'High', 2)
    verify_monitoree_count(active_counts, 4, true, 'Risk Factor', 'Travel from Affected Country or Area', 'Medium', 2)
    verify_monitoree_count(active_counts, 5, true, 'Risk Factor', 'Travel from Affected Country or Area', 'No Identified Risk', 2)
    verify_monitoree_count(active_counts, 6, true, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'Missing', 1)
    verify_monitoree_count(active_counts, 7, true, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'High', 2)
    verify_monitoree_count(active_counts, 8, true, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'Medium', 1)
    verify_monitoree_count(active_counts, 9, true, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 10, true, 'Risk Factor', 'Common Exposure Cohort', 'High', 2)
    verify_monitoree_count(active_counts, 11, true, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'High', 2)
    verify_monitoree_count(active_counts, 12, true, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'Medium', 1)
    verify_monitoree_count(active_counts, 13, true, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 14, true, 'Risk Factor', 'Laboratory Personnel', 'Medium', 1)
    verify_monitoree_count(active_counts, 15, true, 'Risk Factor', 'Laboratory Personnel', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 16, true, 'Risk Factor', 'Total', 'Missing', 2)
    verify_monitoree_count(active_counts, 17, true, 'Risk Factor', 'Total', 'High', 3)
    verify_monitoree_count(active_counts, 18, true, 'Risk Factor', 'Total', 'Medium', 2)
    verify_monitoree_count(active_counts, 19, true, 'Risk Factor', 'Total', 'No Identified Risk', 2)
    assert_equal(20, active_counts.length)

    overall_counts = CacheAnalyticsJob.monitoree_counts_by_risk_factor(1, @@monitorees, false)
    verify_monitoree_count(overall_counts, 0, false, 'Risk Factor', 'Close Contact with Known Case', 'High', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Risk Factor', 'Close Contact with Known Case', 'Low', 1)
    verify_monitoree_count(overall_counts, 2, false, 'Risk Factor', 'Close Contact with Known Case', 'Medium', 1)
    verify_monitoree_count(overall_counts, 3, false, 'Risk Factor', 'Travel from Affected Country or Area', 'Missing', 1)
    verify_monitoree_count(overall_counts, 4, false, 'Risk Factor', 'Travel from Affected Country or Area', 'High', 2)
    verify_monitoree_count(overall_counts, 5, false, 'Risk Factor', 'Travel from Affected Country or Area', 'Low', 2)
    verify_monitoree_count(overall_counts, 6, false, 'Risk Factor', 'Travel from Affected Country or Area', 'Medium', 2)
    verify_monitoree_count(overall_counts, 7, false, 'Risk Factor', 'Travel from Affected Country or Area', 'No Identified Risk', 2)
    verify_monitoree_count(overall_counts, 8, false, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'Missing', 1)
    verify_monitoree_count(overall_counts, 9, false, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'High', 2)
    verify_monitoree_count(overall_counts, 10, false, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'Low', 1)
    verify_monitoree_count(overall_counts, 11, false, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'Medium', 1)
    verify_monitoree_count(overall_counts, 12, false, 'Risk Factor', 'Was in Healthcare Facility with Known Cases', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 13, false, 'Risk Factor', 'Healthcare Personnel', 'Low', 1)
    verify_monitoree_count(overall_counts, 14, false, 'Risk Factor', 'Common Exposure Cohort', 'High', 2)
    verify_monitoree_count(overall_counts, 15, false, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'High', 2)
    verify_monitoree_count(overall_counts, 16, false, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'Low', 1)
    verify_monitoree_count(overall_counts, 17, false, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'Medium', 1)
    verify_monitoree_count(overall_counts, 18, false, 'Risk Factor', 'Crew on Passenger or Cargo Flight', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 19, false, 'Risk Factor', 'Laboratory Personnel', 'Low', 1)
    verify_monitoree_count(overall_counts, 20, false, 'Risk Factor', 'Laboratory Personnel', 'Medium', 1)
    verify_monitoree_count(overall_counts, 21, false, 'Risk Factor', 'Laboratory Personnel', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 22, false, 'Risk Factor', 'Total', 'Missing', 2)
    verify_monitoree_count(overall_counts, 23, false, 'Risk Factor', 'Total', 'High', 3)
    verify_monitoree_count(overall_counts, 24, false, 'Risk Factor', 'Total', 'Low', 2)
    verify_monitoree_count(overall_counts, 25, false, 'Risk Factor', 'Total', 'Medium', 2)
    verify_monitoree_count(overall_counts, 26, false, 'Risk Factor', 'Total', 'No Identified Risk', 2)
    assert_equal(27, overall_counts.length)
  end

  test 'monitoree counts by exposure country' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_exposure_country(1, @@monitorees, true)
    verify_monitoree_count(active_counts, 0, true, 'Exposure Country', 'China', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 1, true, 'Exposure Country', 'Faroe Islands', 'High', 1)
    verify_monitoree_count(active_counts, 2, true, 'Exposure Country', 'Faroe Islands', 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 3, true, 'Exposure Country', 'Iceland', 'High', 1)
    verify_monitoree_count(active_counts, 4, true, 'Exposure Country', 'Korea', 'Medium', 1)
    verify_monitoree_count(active_counts, 5, true, 'Exposure Country', 'Malaysia', 'Missing', 1)
    verify_monitoree_count(active_counts, 6, true, 'Exposure Country', 'Malaysia', 'High', 1)
    verify_monitoree_count(active_counts, 7, true, 'Exposure Country', 'Malaysia', 'Medium', 1)
    verify_monitoree_count(active_counts, 8, true, 'Exposure Country', 'Total', 'Missing', 2)
    verify_monitoree_count(active_counts, 9, true, 'Exposure Country', 'Total', 'High', 3)
    verify_monitoree_count(active_counts, 10, true, 'Exposure Country', 'Total', 'Medium', 2)
    verify_monitoree_count(active_counts, 11, true, 'Exposure Country', 'Total', 'No Identified Risk', 2)
    assert_equal(12, active_counts.length)

    overall_counts = CacheAnalyticsJob.monitoree_counts_by_exposure_country(1, @@monitorees, false)
    verify_monitoree_count(overall_counts, 0, false, 'Exposure Country', 'Brazil', 'Low', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Exposure Country', 'China', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 2, false, 'Exposure Country', 'Faroe Islands', 'High', 1)
    verify_monitoree_count(overall_counts, 3, false, 'Exposure Country', 'Faroe Islands', 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 4, false, 'Exposure Country', 'Iceland', 'High', 1)
    verify_monitoree_count(overall_counts, 5, false, 'Exposure Country', 'Malaysia', 'Missing', 1)
    verify_monitoree_count(overall_counts, 6, false, 'Exposure Country', 'Malaysia', 'High', 1)
    verify_monitoree_count(overall_counts, 7, false, 'Exposure Country', 'Malaysia', 'Low', 1)
    verify_monitoree_count(overall_counts, 8, false, 'Exposure Country', 'Malaysia', 'Medium', 1)
    verify_monitoree_count(overall_counts, 9, false, 'Exposure Country', 'Total', 'Missing', 2)
    verify_monitoree_count(overall_counts, 10, false, 'Exposure Country', 'Total', 'High', 3)
    verify_monitoree_count(overall_counts, 11, false, 'Exposure Country', 'Total', 'Low', 2)
    verify_monitoree_count(overall_counts, 12, false, 'Exposure Country', 'Total', 'Medium', 2)
    verify_monitoree_count(overall_counts, 13, false, 'Exposure Country', 'Total', 'No Identified Risk', 2)
    assert_equal(14, overall_counts.length)
  end

  test 'monitoree counts by last exposure date' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_last_exposure_date(1, @@monitorees, true)
    verify_monitoree_count(active_counts, 0, true, 'Last Exposure Date', days_ago(27), 'Missing', 1)
    verify_monitoree_count(active_counts, 1, true, 'Last Exposure Date', days_ago(27), 'Medium', 1)
    verify_monitoree_count(active_counts, 2, true, 'Last Exposure Date', days_ago(26), 'High', 1)
    verify_monitoree_count(active_counts, 3, true, 'Last Exposure Date', days_ago(22), 'Low', 1)
    verify_monitoree_count(active_counts, 4, true, 'Last Exposure Date', days_ago(22), 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 5, true, 'Last Exposure Date', days_ago(12), 'Missing', 2)
    verify_monitoree_count(active_counts, 6, true, 'Last Exposure Date', days_ago(11), 'Missing', 4)
    verify_monitoree_count(active_counts, 7, true, 'Last Exposure Date', days_ago(10), 'Missing', 1)
    verify_monitoree_count(active_counts, 8, true, 'Last Exposure Date', days_ago(9), 'Missing', 2)
    verify_monitoree_count(active_counts, 9, true, 'Last Exposure Date', days_ago(8), 'Missing', 1)
    verify_monitoree_count(active_counts, 10, true, 'Last Exposure Date', days_ago(5), 'Missing', 2)
    verify_monitoree_count(active_counts, 11, true, 'Last Exposure Date', days_ago(4), 'Missing', 1)
    verify_monitoree_count(active_counts, 12, true, 'Last Exposure Date', days_ago(3), 'Missing', 1)
    verify_monitoree_count(active_counts, 13, true, 'Last Exposure Date', days_ago(1), 'High', 1)
    assert_equal(14, active_counts.length)

    overall_counts = CacheAnalyticsJob.monitoree_counts_by_last_exposure_date(1, @@monitorees, false)
    verify_monitoree_count(overall_counts, 0, false, 'Last Exposure Date', days_ago(27), 'Missing', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Last Exposure Date', days_ago(27), 'Medium', 1)
    verify_monitoree_count(overall_counts, 2, false, 'Last Exposure Date', days_ago(26), 'High', 1)
    verify_monitoree_count(overall_counts, 3, false, 'Last Exposure Date', days_ago(22), 'Low', 1)
    verify_monitoree_count(overall_counts, 4, false, 'Last Exposure Date', days_ago(22), 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 5, false, 'Last Exposure Date', days_ago(12), 'Missing', 2)
    verify_monitoree_count(overall_counts, 6, false, 'Last Exposure Date', days_ago(11), 'Missing', 4)
    verify_monitoree_count(overall_counts, 7, false, 'Last Exposure Date', days_ago(10), 'Missing', 1)
    verify_monitoree_count(overall_counts, 8, false, 'Last Exposure Date', days_ago(9), 'Missing', 2)
    verify_monitoree_count(overall_counts, 9, false, 'Last Exposure Date', days_ago(8), 'Missing', 1)
    verify_monitoree_count(overall_counts, 10, false, 'Last Exposure Date', days_ago(5), 'Missing', 2)
    verify_monitoree_count(overall_counts, 11, false, 'Last Exposure Date', days_ago(4), 'Missing', 1)
    verify_monitoree_count(overall_counts, 12, false, 'Last Exposure Date', days_ago(3), 'Missing', 1)
    verify_monitoree_count(overall_counts, 13, false, 'Last Exposure Date', days_ago(1), 'High', 1)
    assert_equal(14, overall_counts.length)
  end

  test 'monitoree counts by last exposure week' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_last_exposure_week(1, @@monitorees_by_exposure_week, true)
    verify_monitoree_count(active_counts, 0, true, 'Last Exposure Week', weeks_ago(52), 'Missing', 1)
    verify_monitoree_count(active_counts, 1, true, 'Last Exposure Week', weeks_ago(25), 'Low', 2)
    verify_monitoree_count(active_counts, 2, true, 'Last Exposure Week', weeks_ago(19), 'Medium', 1)
    verify_monitoree_count(active_counts, 3, true, 'Last Exposure Week', weeks_ago(3), 'High', 1)
    verify_monitoree_count(active_counts, 4, true, 'Last Exposure Week', weeks_ago(1), 'High', 1)
    assert_equal(5, active_counts.length)

    overall_counts = CacheAnalyticsJob.monitoree_counts_by_last_exposure_week(1, @@monitorees_by_exposure_week, false)
    verify_monitoree_count(overall_counts, 0, false, 'Last Exposure Week', weeks_ago(52), 'Missing', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Last Exposure Week', weeks_ago(25), 'Low', 2)
    verify_monitoree_count(overall_counts, 2, false, 'Last Exposure Week', weeks_ago(21), 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 3, false, 'Last Exposure Week', weeks_ago(19), 'Medium', 1)
    verify_monitoree_count(overall_counts, 4, false, 'Last Exposure Week', weeks_ago(11), 'Medium', 1)
    verify_monitoree_count(overall_counts, 5, false, 'Last Exposure Week', weeks_ago(3), 'High', 1)
    verify_monitoree_count(overall_counts, 6, false, 'Last Exposure Week', weeks_ago(3), 'Low', 1)
    verify_monitoree_count(overall_counts, 7, false, 'Last Exposure Week', weeks_ago(1), 'High', 1)
    assert_equal(8, overall_counts.length)
  end

  test 'monitoree counts by last exposure month' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_last_exposure_month(1, @@monitorees_by_exposure_month, true)
    verify_monitoree_count(active_counts, 0, true, 'Last Exposure Month', months_ago(13), 'Low', 1)
    verify_monitoree_count(active_counts, 1, true, 'Last Exposure Month', months_ago(11), 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 2, true, 'Last Exposure Month', months_ago(5), 'Low', 1)
    verify_monitoree_count(active_counts, 3, true, 'Last Exposure Month', months_ago(5), 'No Identified Risk', 1)
    verify_monitoree_count(active_counts, 4, true, 'Last Exposure Month', months_ago(2), 'Medium', 1)
    verify_monitoree_count(active_counts, 5, true, 'Last Exposure Month', months_ago(1), 'High', 1)
    verify_monitoree_count(active_counts, 6, true, 'Last Exposure Month', months_ago(1), 'Low', 1)
    assert_equal(7, active_counts.length)

    overall_counts = CacheAnalyticsJob.monitoree_counts_by_last_exposure_month(1, @@monitorees_by_exposure_month, false)
    verify_monitoree_count(overall_counts, 0, false, 'Last Exposure Month', months_ago(13), 'Low', 1)
    verify_monitoree_count(overall_counts, 1, false, 'Last Exposure Month', months_ago(11), 'Medium', 1)
    verify_monitoree_count(overall_counts, 2, false, 'Last Exposure Month', months_ago(11), 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 3, false, 'Last Exposure Month', months_ago(5), 'Low', 1)
    verify_monitoree_count(overall_counts, 4, false, 'Last Exposure Month', months_ago(5), 'No Identified Risk', 1)
    verify_monitoree_count(overall_counts, 5, false, 'Last Exposure Month', months_ago(2), 'Medium', 2)
    verify_monitoree_count(overall_counts, 6, false, 'Last Exposure Month', months_ago(1), 'High', 1)
    verify_monitoree_count(overall_counts, 7, false, 'Last Exposure Month', months_ago(1), 'Low', 1)
    assert_equal(8, overall_counts.length)
  end

  test 'monitoree snapshots' do
    snapshots = CacheAnalyticsJob.all_monitoree_snapshots(1, @@monitorees, 1)
    verify_snapshot(snapshots, 0, 'Last 24 Hours', 5, 0, 2, 0)
    verify_snapshot(snapshots, 2, 'Total', 34, 0, 3, 0)

    snapshots = CacheAnalyticsJob.all_monitoree_snapshots(1, Patient.where(jurisdiction_id: 2), 2)
    verify_snapshot(snapshots, 0, 'Last 24 Hours', 2, 1, 1, 1)
    verify_snapshot(snapshots, 2, 'Total', 16, 2, 1, 2)
  end

  test 'state level maps' do
    maps = CacheAnalyticsJob.state_level_maps(1, @@monitorees)
    verify_map(maps, 0, 'State', 'Exposure', nil, nil, 2)
    verify_map(maps, 1, 'State', 'Exposure', 'California', nil, 4)
    verify_map(maps, 2, 'State', 'Exposure', 'Delaware', nil, 2)
    verify_map(maps, 3, 'State', 'Exposure', 'Massachusetts', nil, 7)
    verify_map(maps, 4, 'State', 'Exposure', 'New Mexico', nil, 2)
    verify_map(maps, 5, 'State', 'Exposure', 'New York', nil, 4)
    verify_map(maps, 6, 'State', 'Isolation', 'California', nil, 6)
    verify_map(maps, 7, 'State', 'Isolation', 'Massachusetts', nil, 1)
    verify_map(maps, 8, 'State', 'Isolation', 'New York', nil, 1)
    verify_map(maps, 9, 'State', 'Isolation', 'Utah', nil, 2)
    assert_equal(10, maps.length)
  end

  test 'county level maps' do
    maps = CacheAnalyticsJob.county_level_maps(1, @@monitorees)
    verify_map(maps, 0, 'County', 'Exposure', nil, nil, 1)
    verify_map(maps, 1, 'County', 'Exposure', nil, 'Lake', 1)
    verify_map(maps, 2, 'County', 'Exposure', 'California', nil, 2)
    verify_map(maps, 3, 'County', 'Exposure', 'California', 'Monroe', 2)
    verify_map(maps, 4, 'County', 'Exposure', 'Delaware', 'Jackson', 1)
    verify_map(maps, 5, 'County', 'Exposure', 'Delaware', 'Pike', 1)
    verify_map(maps, 6, 'County', 'Exposure', 'Massachusetts', 'Jackson', 1)
    verify_map(maps, 7, 'County', 'Exposure', 'Massachusetts', 'Lake', 3)
    verify_map(maps, 8, 'County', 'Exposure', 'Massachusetts', 'Suffolk', 3)
    verify_map(maps, 9, 'County', 'Exposure', 'New Mexico', nil, 2)
    verify_map(maps, 10, 'County', 'Exposure', 'New York', nil, 2)
    verify_map(maps, 11, 'County', 'Exposure', 'New York', 'Monroe', 1)
    verify_map(maps, 12, 'County', 'Exposure', 'New York', 'Pike', 1)
    verify_map(maps, 13, 'County', 'Isolation', 'California', nil, 6)
    verify_map(maps, 14, 'County', 'Isolation', 'Massachusetts', nil, 1)
    verify_map(maps, 15, 'County', 'Isolation', 'New York', nil, 1)
    verify_map(maps, 16, 'County', 'Isolation', 'Utah', nil, 2)
    assert_equal(17, maps.length)
  end

  # rubocop:disable Metrics/ParameterLists
  def verify_monitoree_count(counts, index, active_monitoring, category_type, category, risk_level, total)
    assert_equal(1, counts[index].analytic_id, monitoree_count_err_msg(index, active_monitoring, category_type))
    assert_equal(active_monitoring, counts[index].active_monitoring, monitoree_count_err_msg(index, active_monitoring, category_type))
    assert_equal(category_type, counts[index].category_type, monitoree_count_err_msg(index, active_monitoring, category_type))
    assert_equal(category, counts[index].category, monitoree_count_err_msg(index, active_monitoring, category_type))
    assert_equal(risk_level, counts[index].risk_level, monitoree_count_err_msg(index, active_monitoring, category_type))
    assert_equal(total, counts[index].total, monitoree_count_err_msg(index, active_monitoring, category_type))
  end

  def verify_snapshot(snapshots, index, time_frame, new_enrollments, transferred_in, closed, transferred_out)
    assert_equal(1, snapshots[index].analytic_id, 'Analytic ID')
    assert_equal(time_frame, snapshots[index].time_frame, 'Time frame')
    assert_equal(new_enrollments, snapshots[index].new_enrollments, 'New enrollments')
    assert_equal(transferred_in, snapshots[index].transferred_in, 'Incoming transfers')
    assert_equal(closed, snapshots[index].closed, 'Closed patients')
    assert_equal(transferred_out, snapshots[index].transferred_out, 'Outgoing transfers')
  end

  def verify_map(maps, index, level, workflow, state, county, total)
    assert_equal(1, maps[index].analytic_id, 'Analytic ID')
    assert_equal(level, maps[index].level, 'Level')
    assert_equal(workflow, maps[index].workflow, 'Workflow')
    if state.nil?
      assert_nil(maps[index].state, 'State')
    else
      assert_equal(state, maps[index].state, 'State')
    end
    if county.nil?
      assert_nil(maps[index].county, 'County')
    else
      assert_equal(county, maps[index].county, 'County')
    end
    assert_equal(total, maps[index].total, 'Total')
  end
  # rubocop:enable Metrics/ParameterLists

  def days_ago(num_days)
    num_days.days.ago.strftime('%F')
  end

  def weeks_ago(num_weeks)
    num_weeks.weeks.ago.beginning_of_week(:sunday).strftime('%F')
  end

  def months_ago(num_months)
    num_months.months.ago.beginning_of_month.strftime('%F')
  end

  def monitoree_count_err_msg(index, active_monitoring, category_type)
    "Incorrect count for #{category_type}: #{index} (#{active_monitoring ? 'active' : 'overall'})"
  end
end
