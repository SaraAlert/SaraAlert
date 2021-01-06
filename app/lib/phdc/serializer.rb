# frozen_string_literal: true

# Module for dealing with PHDC documents
module PHDC
  # Serializer class; meant to be used for multiple conversions at once
  class Serializer
    # Initializer; loads FIPS code lookups
    def initialize
      @fips = FIPS.new
    end

    # Convert many patients to the PHDC format
    def patients_to_phdc_zip(patients, jurisdiction)
      stringio = Zip::OutputStream.write_buffer do |zio|
        patients.each do |patient|
          zio.put_next_entry("records/#{patient.id}.xml")
          zio.write patient_to_phdc(patient, jurisdiction, patient.assessments.where(symptomatic: true))
        end
      end
      stringio.set_encoding('UTF-8')
    end

    # Convert a single patient to the PHDC format
    def patient_to_phdc(patient, jurisdiction, symptomatic_assessments) # rubocop:todo Metrics/MethodLength
      doc = Ox::Document.new

      # Document Headers
      instruct_xml = Ox::Instruct.new(:xml)
      instruct_xml['version'] = '1.0'
      instruct_xml['encoding'] = 'UTF-8'
      doc << instruct_xml

      instruct_xml_s = Ox::Instruct.new(:'xml-stylesheet')
      instruct_xml_s['type'] = 'text/xsl'
      instruct_xml_s['href'] = 'PHDC.xsl'
      doc << instruct_xml_s

      # Root ClinicalDocument element
      cd_root = Ox::Element.new('ClinicalDocument')
      cd_root['xmlns:xsi'] = 'http://www.w3.org/2001/XMLSchema-instance'
      cd_root['xsi:schemaLocation'] = 'urn:hl7-org:v3 CDA_SDTC.xsd'
      cd_root['xmlns'] = 'urn:hl7-org:v3'
      cd_root['xmlns:sdtc'] = 'urn:hl7-org:sdtc'
      doc << cd_root

      # ClinicalDocument Headers

      # Realm code
      realm_code = Ox::Element.new(:realmCode)
      realm_code['code'] = 'US'
      cd_root << realm_code

      # Type ID
      type_id = Ox::Element.new(:typeId)
      type_id['root'] = '2.16.840.1.113883.1.3'
      type_id['extension'] = 'POCD_HD000040'
      cd_root << type_id

      # ID
      cdid = Ox::Element.new(:id)
      cdid['root'] = '2.16.840.1.113883.19'
      cdid['extension'] = patient.id
      cd_root << cdid

      # Code
      cd_root << code_helper('55751-2', '2.16.840.1.113883.6.1', 'Public Health Case Report', 'LOINC')

      # Title
      title = Ox::Element.new(:title)
      title << 'Sara Alert NBS Export'
      cd_root << title

      # Effective time
      effective_time = Ox::Element.new(:effectiveTime)
      effective_time['value'] = patient.updated_at.strftime('%Y%m%d%H%M%S%z')
      cd_root << effective_time

      # Confidentiality code
      confidentiality_code = Ox::Element.new(:confidentialityCode)
      confidentiality_code['code'] = 'N'
      confidentiality_code['codeSystem'] = '2.16.840.1.113883.5.25'
      cd_root << confidentiality_code

      # Language
      language_code = Ox::Element.new(:languageCode)
      language_code['code'] = 'ENG'
      cd_root << language_code

      # ID
      set_id = Ox::Element.new(:setId)
      set_id['root'] = '2.16.840.1.113883.19'
      set_id['extension'] = patient.id
      cd_root << set_id

      # Version number
      version_number = Ox::Element.new(:versionNumber)
      version_number['value'] = '1'
      cd_root << version_number

      # Record Target
      record_target = Ox::Element.new(:recordTarget)
      cd_root << record_target
      patient_role = Ox::Element.new(:patientRole)
      record_target << patient_role
      patient_role_id = Ox::Element.new(:id)
      patient_role_id['root'] = '2.16.840.1.113883.19'
      patient_role_id['extension'] = patient.id
      patient_role << patient_role_id

      # Address
      addr = Ox::Element.new(:addr)
      addr['use'] = 'H'
      patient_role << addr
      street_address_line = Ox::Element.new(:streetAddressLine)
      street_address_line << (patient.address_line_1 || '')
      addr << street_address_line unless patient.address_line_1.blank?
      city_address = Ox::Element.new(:city)
      city_address << (patient.address_city || '')
      addr << city_address unless patient.address_city.blank?
      state_address = Ox::Element.new(:state)
      state_address << "#{@fips.state_to_fips(patient.address_state)}^#{patient.address_state}^FIPS 5-2 (State)"
      addr << state_address unless patient.address_state.blank?
      zip_address = Ox::Element.new(:postalCode)
      zip_address << (patient.address_zip || '')
      addr << zip_address unless patient.address_zip.blank?
      county_address = Ox::Element.new(:county)
      county_address << "#{@fips.county_to_fips(patient.address_state, patient.address_county)}^#{patient.address_county}^FIPS 6-4 (County)"
      addr << county_address unless patient.address_state.blank? || patient.address_county.blank?
      country_address = Ox::Element.new(:country)
      country_address << '840^United States^Country (ISO 3166-1)'
      addr << country_address

      # Telecom
      telecom = Ox::Element.new(:telecom)
      telecom['use'] = 'HP'
      telecom['value'] = patient.primary_telephone || patient.secondary_telephone
      patient_role << telecom unless patient.primary_telephone.blank? && patient.secondary_telephone.blank?

      # Patient Details

      # Name
      patient_details = Ox::Element.new(:patient)
      patient_role << patient_details
      name = Ox::Element.new(:name)
      name['use'] = 'L'
      patient_details << name
      given_first = Ox::Element.new(:given)
      given_first << (patient.first_name || '')
      name << given_first unless patient.first_name.blank?
      given_middle = Ox::Element.new(:given)
      given_middle << (patient.middle_name || '')
      name << given_middle unless patient.middle_name.blank?
      last_name = Ox::Element.new(:family)
      last_name << (patient.last_name || '')
      name << last_name unless patient.last_name.blank?

      # Sex
      unless patient.sex.blank?
        patient_details << code_helper(patient.sex&.first, '2.16.840.1.113883.12.1', patient.sex, 'Administrative sex (HL7)', :administrativeGenderCode)
      end

      # Birthdate
      birthdate = Ox::Element.new(:birthTime)
      birthdate['value'] = patient.date_of_birth&.strftime('%Y%m%d')
      patient_details << birthdate unless patient.date_of_birth&.strftime('%Y%m%d').blank?

      # Race
      r_oid = '2.16.840.1.113883.6.238'
      patient_details << code_helper('2106-3', r_oid, 'White', 'Race & Ethnicity - CDC', 'sdtc:raceCode') if patient.white
      if patient.black_or_african_american
        patient_details << code_helper('2054-5', r_oid, 'Black or African American', 'Race & Ethnicity - CDC', 'sdtc:raceCode')
      end
      if patient.american_indian_or_alaska_native
        patient_details << code_helper('1002-5', r_oid, 'American Indian or Alaska Native', 'Race & Ethnicity - CDC', 'sdtc:raceCode')
      end
      patient_details << code_helper('2028-9', r_oid, 'Asian', 'Race & Ethnicity - CDC', 'sdtc:raceCode') if patient.asian
      if patient.native_hawaiian_or_other_pacific_islander
        patient_details << code_helper('2076-8', r_oid, 'Native Hawaiian or Other Pacific Islander', 'Race & Ethnicity - CDC', 'sdtc:raceCode')
      end

      # Ethnicity
      unless patient.ethnicity.blank?
        eth_code = patient.ethnicity.include?('Not') ? '2186-5' : '2135-2'
        patient_details << code_helper(eth_code, r_oid, patient.ethnicity, 'Race & Ethnicity - CDC', :ethnicGroupCode)
      end

      # Author
      author = Ox::Element.new(:author)
      cd_root << author
      auth_time = Ox::Element.new(:time)
      auth_time['value'] = patient.created_at&.strftime('%Y%m%d%H%M%S%z')
      author << auth_time
      assigned_author = Ox::Element.new(:assignedAuthor)
      author << assigned_author
      auth_id = Ox::Element.new(:id)
      auth_id['root'] = '2.16.840.1.113883.19.5'
      assigned_author << auth_id
      assigned_person = Ox::Element.new(:assignedPerson)
      assigned_author << assigned_person
      auth_name = Ox::Element.new(:name)
      assigned_person << auth_name
      jur_name = Ox::Element.new(:family)
      jur_name << "Sara Alert NBS Export: #{jurisdiction.jurisdiction_path_string}"
      auth_name << jur_name

      # Custodian
      custodian = Ox::Element.new(:custodian)
      cd_root << custodian
      assigned_custodian = Ox::Element.new(:assignedCustodian)
      custodian << assigned_custodian
      represented_custodian_organization = Ox::Element.new(:representedCustodianOrganization)
      assigned_custodian << represented_custodian_organization
      custodian_id = Ox::Element.new(:id)
      custodian_id['root'] = '1.3.3.3.333.23'
      represented_custodian_organization << custodian_id
      jur_name_cust = Ox::Element.new(:name)
      jur_name_cust << "Sara Alert NBS Export: #{jurisdiction.jurisdiction_path_string}"
      represented_custodian_organization << jur_name_cust

      # Body
      outer_component = Ox::Element.new(:component)
      cd_root << outer_component
      structured_body = Ox::Element.new(:structuredBody)
      outer_component << structured_body

      # Social History Information Section

      sh_component = Ox::Element.new(:component)
      structured_body << sh_component
      sh_section = Ox::Element.new(:section)
      sh_component << sh_section
      sh_id = Ox::Element.new(:id)
      sh_id['root'] = '2.16.840.1.113883.19'
      sh_id['extension'] = patient.id
      sh_section << sh_id
      sh_section << code_helper('29762-2', '2.16.840.1.113883.6.1', 'Social history', 'LOINC')
      sh_section_title = Ox::Element.new(:title)
      sh_section_title << 'SOCIAL HISTORY INFORMATION'
      sh_section << sh_section_title
      if patient.primary_language == 'English'
        sh_section << entry_helper_code('DEM142', 'Patient Primary Language', 'CE', 'ENG', 'English')
        sh_section << entry_helper_code('NBS214', 'Patient Speaks English', 'CE', 'Y', 'Yes')
      end
      unless patient.date_of_birth.blank?
        age = Patient.calc_current_age_base(provided_date_of_birth: patient.date_of_birth).to_s
        sh_section << entry_helper_text('INV2001', 'Patient Age Reported', 'ST', age)
        sh_section << entry_helper_code('INV2002', 'Patient Age Reported Units', 'CE', 'a', 'Year')
      end
      sh_section << entry_helper_text('NBS213', 'Patient Gender (Transgender Information)', 'ST', patient.gender_identity) unless patient.gender_identity.blank?

      # Clinical Information Section

      clin_component = Ox::Element.new(:component)
      structured_body << clin_component
      clin_section = Ox::Element.new(:section)
      clin_component << clin_section
      clin_id = Ox::Element.new(:id)
      clin_id['root'] = '2.16.840.1.113883.19'
      clin_id['extension'] = patient.id
      clin_section << clin_id
      clin_section << code_helper('55752-0', '2.16.840.1.113883.6.1', 'Clinical information', 'LOINC')
      clin_section_title = Ox::Element.new(:title)
      clin_section_title << 'CLINICAL INFORMATION'
      clin_section << clin_section_title
      unless patient.user_defined_id_statelocal.blank?
        clin_section << entry_helper_text('INV168', 'Investigation Local ID', 'ST', patient.user_defined_id_statelocal, nil)
        clin_section << entry_helper_text('INV173', 'Investigation State Local ID', 'ST', patient.user_defined_id_statelocal, nil)
      end

      # Generic Repeating Questions Information Section

      grq_component = Ox::Element.new(:component)
      structured_body << grq_component
      grq_section = Ox::Element.new(:section)
      grq_component << grq_section
      grq_id = Ox::Element.new(:id)
      grq_id['root'] = '2.16.840.1.113883.19'
      grq_id['extension'] = patient.id
      grq_section << grq_id
      grq_section << code_helper('1234567-RPT', 'Local-codesystem-oid', 'Generic Repeating Questions Section', 'LocalSystem')
      grq_section_title = Ox::Element.new(:title)
      grq_section_title << 'GENERIC REPEATING QUESTIONS'
      grq_section << grq_section_title
      qrq_entry = entry_helper('COMP')
      grq_section << qrq_entry
      qrq_org = organizer_helper('CLUSTER', 'EVN')
      qrq_entry << qrq_org
      qrq_org << code_helper('1', 'Local-codesystem-oid', 'Exposure Information', 'LocalSystem')
      qrq_org << status_code_helper('completed')
      unless patient.potential_exposure_country.blank?
        code = code_helper('INV502', 'Local-codesystem-oid', 'Country of Exposure', 'LocalSystem')
        value = value_helper_code('CE', @fips.country_to_alpha_3(patient.potential_exposure_country), '1.0.3166.1', patient.potential_exposure_country)
        qrq_org << comp_obs_helper('OBS', 'EVN', code, value)
      end
      unless patient.potential_exposure_location.blank?
        code = code_helper('INV504', 'Local-codesystem-oid', 'City of Exposure', 'LocalSystem')
        value = value_helper_text('ST', patient.potential_exposure_location)
        qrq_org << comp_obs_helper('OBS', 'EVN', code, value)
      end
      unless patient.exposure_notes.blank?
        qrq_entry_notes = entry_helper('COMP')
        grq_section << qrq_entry_notes
        qrq_org_notes = organizer_helper('CLUSTER', 'EVN')
        qrq_entry_notes << qrq_org_notes
        qrq_org_notes << code_helper('3', 'Local-codesystem-oid', 'Exposure Notes', 'LocalSystem')
        qrq_org_notes << status_code_helper('completed')
        code = code_helper('NBS152', 'Local-codesystem-oid', 'Surveillance Notes', 'LocalSystem')
        value = value_helper_text('ST', patient.exposure_notes)
        qrq_org_notes << comp_obs_helper('OBS', 'EVN', code, value)
      end

      # Signs and Symptoms Information Section

      sas_component = Ox::Element.new(:component)
      structured_body << sas_component
      sas_section = Ox::Element.new(:section)
      sas_component << sas_section
      sas_id = Ox::Element.new(:id)
      sas_id['root'] = '2.16.840.1.113883.19'
      sas_id['extension'] = patient.id
      sas_section << sas_id
      sas_section << code_helper('123-5897', 'Local-codesystem-oid', 'Signs and Symptoms Section', 'LocalSystem')
      sas_section_title = Ox::Element.new(:title)
      sas_section_title << 'SIGNS AND SYMPTOMS'
      sas_section << sas_section_title
      symptomatic_assessments.each do |assessment|
        sas_entry = entry_helper('COMP')
        sas_section << sas_entry
        sas_obs = observation_helper('OBS', 'EVN')
        sas_entry << sas_obs
        sas_obs << code_helper('1', 'Local-codesystem-oid', 'Daily Report', 'LocalSystem')
        effective_time = Ox::Element.new(:effectiveTime)
        effective_time['value'] = assessment.updated_at.strftime('%Y%m%d%H%M%S%z')
        sas_obs << effective_time
        sas_obs << value_helper_code('CE', 'Yes', 'LocalSystem', 'Symptomatic')
      end

      # Return XML
      Ox.dump(doc)
    end

    private

    # Entry helper
    def entry_helper(type = nil)
      entry_el = Ox::Element.new(:entry)
      entry_el['typeCode'] = type unless type.blank?
      entry_el
    end

    # Observation helper
    def observation_helper(class_code, mood_code)
      observation_el = Ox::Element.new(:observation)
      observation_el['classCode'] = class_code
      observation_el['moodCode'] = mood_code
      observation_el
    end

    # Code helper
    def code_helper(code, system, display, system_name = nil, custom_tag = :code)
      code_el = Ox::Element.new(custom_tag)
      code_el['code'] = code
      code_el['codeSystem'] = system
      code_el['codeSystemName'] = system_name unless system_name.blank?
      code_el['displayName'] = display
      code_el
    end

    # Value helper for coded values
    def value_helper_code(type, code, system, display)
      value_el = Ox::Element.new(:value)
      value_el['xsi:type'] = type
      value_el['code'] = code
      value_el['codeSystem'] = system
      value_el['displayName'] = display
      value_el
    end

    # Value helper for text values
    def value_helper_text(type, text)
      value_el = Ox::Element.new(:value)
      value_el['xsi:type'] = type
      value_el << text
      value_el
    end

    # Social History entry helper for coded values
    def entry_helper_code(code, display, type, value_code, value_display, entry_type = 'COMP')
      s_entry = entry_helper(entry_type)
      s_obs = observation_helper('OBS', 'EVN')
      s_entry << s_obs
      s_obs << code_helper(code, '2.16.840.1.114222.4.5.1', display, 'NEDSS Base System')
      s_obs << value_helper_code(type, value_code, '1.2.3.5', value_display)
      s_entry
    end

    # Social History entry helper for text values
    def entry_helper_text(code, display, type, text, entry_type = 'COMP')
      s_entry = entry_helper(entry_type)
      s_obs = observation_helper('OBS', 'EVN')
      s_entry << s_obs
      s_obs << code_helper(code, '2.16.840.1.114222.4.5.1', display, 'NEDSS Base System')
      s_obs << value_helper_text(type, text)
      s_entry
    end

    # Organizer helper
    def organizer_helper(class_code, mood_code)
      organizer_el = Ox::Element.new(:organizer)
      organizer_el['classCode'] = class_code
      organizer_el['moodCode'] = mood_code
      organizer_el
    end

    # Status helper
    def status_code_helper(code)
      status_el = Ox::Element.new(:statusCode)
      status_el['code'] = code
      status_el
    end

    # Component > Observation nested helper
    def comp_obs_helper(class_code, mood_code, code, value)
      component_el = Ox::Element.new(:component)
      observation_el = observation_helper(class_code, mood_code)
      component_el << observation_el
      observation_el << code
      observation_el << value
      component_el
    end
  end
end
