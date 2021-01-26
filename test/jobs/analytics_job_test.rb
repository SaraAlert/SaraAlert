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

    assert_equal(40, MonitoreeCount.where(category_type: 'Age Group').size)
    assert_equal(27, MonitoreeCount.where(category_type: 'Sex').size)
    assert_equal(8, MonitoreeCount.where(category_type: 'Risk Factor').size)
    assert_equal(7, MonitoreeCount.where(category_type: 'Exposure Country').size)
    assert_not_equal(0, MonitoreeCount.where(category_type: 'Last Exposure Date').size)
    assert_not_equal(0, MonitoreeCount.where(category_type: 'Last Exposure Week').size)
    assert_not_equal(0, MonitoreeCount.where(category_type: 'Last Exposure Month').size)
    assert_not_equal(0, MonitoreeCount.all.size)

    assert_equal(20, MonitoreeSnapshot.where(time_frame: 'Last 24 Hours').size)
    assert_equal(20, MonitoreeSnapshot.where(time_frame: 'Last 14 Days').size)
    assert_equal(20, MonitoreeSnapshot.where(time_frame: 'Last 7 Days').size)
    assert_equal(20, MonitoreeSnapshot.where(time_frame: 'Total').size)
    assert_equal(80, MonitoreeSnapshot.all.size)

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

  test 'monitoree counts by age group' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_age_group(1, @@monitorees)
    verify_monitoree_count(active_counts, 0, true, 'Age Group', '0-19', 7)
    verify_monitoree_count(active_counts, 1, true, 'Age Group', '0-19', 2)
    verify_monitoree_count(active_counts, 2, true, 'Age Group', '20-29', 3)
    verify_monitoree_count(active_counts, 3, true, 'Age Group', '20-29', 1)
    verify_monitoree_count(active_counts, 4, true, 'Age Group', '30-39', 3)
    verify_monitoree_count(active_counts, 5, true, 'Age Group', '30-39', 2)
    verify_monitoree_count(active_counts, 6, true, 'Age Group', '40-49', 10)
    verify_monitoree_count(active_counts, 7, true, 'Age Group', '40-49', 9)
    verify_monitoree_count(active_counts, 8, true, 'Age Group', '50-59', 1)
    verify_monitoree_count(active_counts, 9, true, 'Age Group', '50-59', 1)
    verify_monitoree_count(active_counts, 10, true, 'Age Group', '60-69', 1)
    verify_monitoree_count(active_counts, 11, true, 'Age Group', '60-69', 2)
    verify_monitoree_count(active_counts, 12, true, 'Age Group', '70-79', 1)
    verify_monitoree_count(active_counts, 13, true, 'Age Group', '>=80', 1)
    assert_equal(14, active_counts.length)
  end

  test 'monitoree counts by sex' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_sex(1, @@monitorees)
    verify_monitoree_count(active_counts, 0, true, 'Sex', 'Missing', 2)
    verify_monitoree_count(active_counts, 1, true, 'Sex', 'Female', 10)
    verify_monitoree_count(active_counts, 2, true, 'Sex', 'Female', 6)
    verify_monitoree_count(active_counts, 3, true, 'Sex', 'Male', 11)
    verify_monitoree_count(active_counts, 4, true, 'Sex', 'Male', 10)
    verify_monitoree_count(active_counts, 5, true, 'Sex', 'Unknown', 3)
    verify_monitoree_count(active_counts, 6, true, 'Sex', 'Unknown', 2)
    assert_equal(7, active_counts.length)
  end

  test 'monitoree counts by exposure country' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_exposure_country(1, @@monitorees)
    verify_monitoree_count(active_counts, 0, true, 'Exposure Country', 'China', 1)
    verify_monitoree_count(active_counts, 1, true, 'Exposure Country', 'Faroe Islands', 2)
    verify_monitoree_count(active_counts, 2, true, 'Exposure Country', 'Iceland', 1)
    verify_monitoree_count(active_counts, 3, true, 'Exposure Country', 'Korea', 1)
    verify_monitoree_count(active_counts, 4, true, 'Exposure Country', 'Malaysia', 3)
    assert_equal(5, active_counts.length)
  end

  test 'monitoree counts by last exposure date' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_last_exposure_date(1, @@monitorees)
    verify_monitoree_count(active_counts, 0, true, 'Last Exposure Date', days_ago(27), 2)
    verify_monitoree_count(active_counts, 1, true, 'Last Exposure Date', days_ago(26), 1)
    verify_monitoree_count(active_counts, 2, true, 'Last Exposure Date', days_ago(22), 2)
    verify_monitoree_count(active_counts, 3, true, 'Last Exposure Date', days_ago(11), 2)
    verify_monitoree_count(active_counts, 4, true, 'Last Exposure Date', days_ago(5), 6)
    verify_monitoree_count(active_counts, 5, true, 'Last Exposure Date', days_ago(3), 1)
    verify_monitoree_count(active_counts, 6, true, 'Last Exposure Date', days_ago(1), 1)
    assert_equal(8, active_counts.length)
  end

  test 'monitoree counts by last exposure week' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_last_exposure_week(1, @@monitorees_by_exposure_week)
    verify_monitoree_count(active_counts, 0, true, 'Last Exposure Week', weeks_ago(52), 1)
    verify_monitoree_count(active_counts, 1, true, 'Last Exposure Week', weeks_ago(25), 2)
    verify_monitoree_count(active_counts, 2, true, 'Last Exposure Week', weeks_ago(19), 1)
    verify_monitoree_count(active_counts, 3, true, 'Last Exposure Week', weeks_ago(3), 1)
    verify_monitoree_count(active_counts, 4, true, 'Last Exposure Week', weeks_ago(1), 1)
    assert_equal(5, active_counts.length)
  end

  test 'monitoree counts by last exposure month' do
    active_counts = CacheAnalyticsJob.monitoree_counts_by_last_exposure_month(1, @@monitorees_by_exposure_month)
    verify_monitoree_count(active_counts, 0, true, 'Last Exposure Month', months_ago(13), 1)
    verify_monitoree_count(active_counts, 1, true, 'Last Exposure Month', months_ago(11), 1)
    verify_monitoree_count(active_counts, 2, true, 'Last Exposure Month', months_ago(5), 2)
    verify_monitoree_count(active_counts, 3, true, 'Last Exposure Month', months_ago(2), 1)
    verify_monitoree_count(active_counts, 4, true, 'Last Exposure Month', months_ago(1), 2)
    assert_equal(5, active_counts.length)
  end

  # TODO: Test is intermittently failing - needs to be investigated when Analytics are revisited
  #   test 'monitoree snapshots' do
  #     snapshots = CacheAnalyticsJob.all_monitoree_snapshots(1, @@monitorees, 1)
  #     verify_snapshot(snapshots, 0, 'Last 24 Hours', 3, 0, 2, 0)
  #     verify_snapshot(snapshots, 1, 'Last 24 Hours', 2, 0, 0, 0)
  #     verify_snapshot(snapshots, 2, 'Last 7 Days', 14, 0, 1, 0)
  #     verify_snapshot(snapshots, 3, 'Last 7 Days', 12, 0, 0, 0)
  #     verify_snapshot(snapshots, 4, 'Last 14 Days', 18, 0, 1, 0)
  #     verify_snapshot(snapshots, 5, 'Last 14 Days', 13, 0, 0, 0)
  #     verify_snapshot(snapshots, 6, 'Total', 29, 0, 3, 0)
  #     verify_snapshot(snapshots, 7, 'Total', 15, 0, 0, 0)

  #     snapshots = CacheAnalyticsJob.all_monitoree_snapshots(1, Patient.where(jurisdiction_id: 2), 2)
  #     verify_snapshot(snapshots, 0, 'Last 24 Hours', 0, 1, 1, 1)
  #     verify_snapshot(snapshots, 1, 'Last 24 Hours', 2, 0, 0, 0)
  #     verify_snapshot(snapshots, 2, 'Last 7 Days', 5, 1, 0, 1)
  #     verify_snapshot(snapshots, 3, 'Last 7 Days', 11, 0, 0, 0)
  #     verify_snapshot(snapshots, 4, 'Last 14 Days', 7, 1, 0, 1)
  #     verify_snapshot(snapshots, 5, 'Last 14 Days', 11, 0, 0, 0)
  #     verify_snapshot(snapshots, 6, 'Total', 13, 2, 1, 2)
  #     verify_snapshot(snapshots, 7, 'Total', 13, 0, 0, 0)
  #   end

  test 'monitoree snapshots transfer from jurisdiction to subjurisdiction' do
    Transfer.destroy_all
    Patient.destroy_all
    usa_jur = Jurisdiction.first
    state_1_jur = usa_jur.children.first
    county_1_jur = state_1_jur.children.first
    patient = create(:patient, jurisdiction_id: county_1_jur.id)
    Transfer.create(who_id: 1, patient_id: patient.id, from_jurisdiction_id: state_1_jur.id, to_jurisdiction_id: county_1_jur.id)

    usa_jur_snapshot = CacheAnalyticsJob.all_monitoree_snapshots(usa_jur.id, @@monitorees, usa_jur.subtree_ids).first
    assert_equal(0, usa_jur_snapshot[:transferred_in])
    assert_equal(0, usa_jur_snapshot[:transferred_out])

    state_1_jur_snapshot = CacheAnalyticsJob.all_monitoree_snapshots(state_1_jur.id, @@monitorees, state_1_jur.subtree_ids).first
    assert_equal(0, state_1_jur_snapshot[:transferred_in])
    assert_equal(0, state_1_jur_snapshot[:transferred_out])

    county_1_jur_snapshot = CacheAnalyticsJob.all_monitoree_snapshots(county_1_jur.id, @@monitorees, county_1_jur.subtree_ids).first
    assert_equal(1, county_1_jur_snapshot[:transferred_in])
    assert_equal(0, county_1_jur_snapshot[:transferred_out])
  end

  test 'monitoree snapshots transfer from jurisdiction to jurisdiction outside of hierarchy' do
    Transfer.destroy_all
    Patient.destroy_all
    usa_jur = Jurisdiction.first
    state_1_jur = usa_jur.children.first
    state_2_jur = usa_jur.children.second
    patient = create(:patient, jurisdiction_id: state_2_jur.id)
    Transfer.create(who_id: 1, patient_id: patient.id, from_jurisdiction_id: state_1_jur.id, to_jurisdiction_id: state_2_jur.id)

    usa_jur_snapshot = CacheAnalyticsJob.all_monitoree_snapshots(usa_jur.id, @@monitorees, usa_jur.subtree_ids).first
    assert_equal(0, usa_jur_snapshot[:transferred_in])
    assert_equal(0, usa_jur_snapshot[:transferred_out])

    state_1_jur_snapshot = CacheAnalyticsJob.all_monitoree_snapshots(state_1_jur.id, @@monitorees, state_1_jur.subtree_ids).first
    assert_equal(0, state_1_jur_snapshot[:transferred_in])
    assert_equal(1, state_1_jur_snapshot[:transferred_out])

    state_2_jur_snapshot = CacheAnalyticsJob.all_monitoree_snapshots(state_2_jur.id, @@monitorees, state_2_jur.subtree_ids).first
    assert_equal(1, state_2_jur_snapshot[:transferred_in])
    assert_equal(0, state_2_jur_snapshot[:transferred_out])
  end

  test 'state level maps' do
    maps = CacheAnalyticsJob.state_level_maps(1, @@monitorees)
    verify_map(maps, 0, 'State', 'Exposure', nil, nil, 2)
    verify_map(maps, 1, 'State', 'Exposure', 'California', nil, 4)
    verify_map(maps, 2, 'State', 'Exposure', 'Delaware', nil, 2)
    verify_map(maps, 3, 'State', 'Exposure', 'Massachusetts', nil, 7)
    verify_map(maps, 4, 'State', 'Exposure', 'New Mexico', nil, 7)
    verify_map(maps, 5, 'State', 'Exposure', 'New York', nil, 4)
    verify_map(maps, 6, 'State', 'Isolation', 'California', nil, 6)
    verify_map(maps, 7, 'State', 'Isolation', 'Massachusetts', nil, 1)
    verify_map(maps, 8, 'State', 'Isolation', 'New York', nil, 1)
    verify_map(maps, 9, 'State', 'Isolation', 'Utah', nil, 10)
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
    verify_map(maps, 9, 'County', 'Exposure', 'New Mexico', nil, 7)
    verify_map(maps, 10, 'County', 'Exposure', 'New York', nil, 2)
    verify_map(maps, 11, 'County', 'Exposure', 'New York', 'Monroe', 1)
    verify_map(maps, 12, 'County', 'Exposure', 'New York', 'Pike', 1)
    verify_map(maps, 13, 'County', 'Isolation', 'California', nil, 6)
    verify_map(maps, 14, 'County', 'Isolation', 'Massachusetts', nil, 1)
    verify_map(maps, 15, 'County', 'Isolation', 'New York', nil, 1)
    verify_map(maps, 16, 'County', 'Isolation', 'Utah', nil, 10)
    assert_equal(17, maps.length)
  end

  def verify_monitoree_count(counts, index, active_monitoring, category_type, category, total)
    assert_equal(1, counts[index].analytic_id, monitoree_count_err_msg(index, active_monitoring, category_type))
    assert_equal(active_monitoring, counts[index].active_monitoring, monitoree_count_err_msg(index, active_monitoring, category_type))
    assert_equal(category_type, counts[index].category_type, monitoree_count_err_msg(index, active_monitoring, category_type))
    assert_equal(category, counts[index].category, monitoree_count_err_msg(index, active_monitoring, category_type))
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
