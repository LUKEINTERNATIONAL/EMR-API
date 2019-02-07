# frozen_string_literal: true

require 'logger'

class DDEService
  DDE_CONFIG_PATH = 'config/application.yml'
  LOGGER = Logger.new(STDOUT)

  cattr_accessor :connection # Holds current (shared) connection to DDE

  include ModelUtils

  # Registers local OpenMRS patient in DDE
  #
  # On success patient get two identifiers under the types
  # 'DDE person document ID' and 'National id'. The
  # 'DDE person document ID' is the patient's record ID in the local
  # DDE instance and the 'National ID' is the national unique identifier
  # for the patient.
  def create_patient(patient)
    push_local_patient_to_dde(patient)
  end

  # Updates patient demographics in DDE.
  #
  # Local patient is not affected in anyway by the update
  def update_patient(patient)
    dde_patient = openmrs_to_dde_patient(patient)
    response, status = dde_client.post('update_person', dde_patient)

    raise "Failed to update person in DDE: #{response}" unless status == 200

    patient
  end

  # Import patients from DDE using doc id
  def import_patients_by_doc_id(doc_id)
    doc_id_type = patient_identifier_type('DDE person document id')
    locals = patient_service.find_patients_by_identifier(doc_id, doc_id_type)
    remotes = find_remote_patients_by_doc_id(doc_id)

    import_remote_patient(locals, remotes)
  end

  # Imports patients from DDE to the local database
  def import_patients_by_npid(npid)
    doc_id_type = patient_identifier_type('National id')
    locals = patient_service.find_patients_by_identifier(npid, doc_id_type)
    remotes = find_remote_patients_by_npid(npid)

    import_remote_patient(locals, remotes)
  end

  # Similar to import_patients_by_npid but uses name and gender instead of npid
  def import_patients_by_name_and_gender(given_name, family_name, gender)
    locals = patient_service.find_patients_by_name_and_gender(given_name, family_name, gender)
    remotes = find_remote_patients_by_name_and_gender(given_name, family_name, gender)

    import_remote_patient(locals, remotes)
  end

  def find_patients_by_npid(npid)
    locals = patient_service.find_patients_by_npid(npid)
    remotes = find_remote_patients_by_npid(npid)

    package_patients(locals, remotes)
  end

  def find_patients_by_name_and_gender(given_name, family_name, gender)
    locals = patient_service.find_patients_by_name_and_gender(given_name, family_name, gender)
    remotes = find_remote_patients_by_name_and_gender(given_name, family_name, gender)

    package_patients(locals, remotes)
  end

  # Matches patients using a bunch of demographics
  def match_patients_by_demographics(family_name:, given_name:, birthdate:, gender:,
                                     home_district:, home_traditional_authority:,
                                     home_village:)
    response, status = dde_client.post(
      'search/people', family_name: family_name,
                       given_name: given_name,
                       gender: gender,
                       attributes: {
                         home_district: home_district,
                         home_traditional_authority: home_traditional_authority,
                         home_village: home_village
                       }
    )

    raise "DDE patient search failed: #{status} - #{response}" unless status == 200

    response.collect do |match|
      doc_id = match['person']['id']
      patient = patient_service.find_patients_by_identifier(
        doc_id, patient_identifier_type('DDE person document id')
      ).first
      match['person']['patient_id'] = patient&.id
      match
    end
  end

  # Trigger a merge of patients in DDE
  def merge_patients(primary, secondary)
    if remote_local_merge?(primary, secondary)
      merge_remote_and_local_patients(primary, secondary)
    elsif remote_only_merge?(primary, secondary)
      merge_remote_patients(primary, secondary)
    else # local - local merge
      raise 'local - local merge not implemented'
    end
  end

  def merge_remote_and_local_patients(primary, secondary)
    response, status = dde_client.post('search_by_doc_id', doc_id: patient['doc_id'])

    raise "Failed to search for patient on remote: #{status} - #{response}" unless status == 200

    local_patient = patient_service.find_patients_by_identifier('National id', primary['npid'])

    link_local_to_dde_patient(local_patient, response)
  end

  def merge_remote_patients(primary, secondary)
    response, status = dde_client.post('merge_people', primary_person_doc_id: primary['doc_id'],
                                                       secondary_person_doc_id: secondary['doc_id'])

    raise "Failed to search for patient on remote: #{status} - #{response}" unless status == 200

    raise "Don't know what to do after this"
  end

  def reassign_patient_npid(dde_patient_doc_id)
    response, status = dde_client.post('assign_npid', doc_id: dde_patient_doc_id)

    raise "Failed to reassign npid: DDE Response => #{status} - #{response}" unless status == 200

    patient = patient_service.find_patients_by_identifier(
      dde_patient_doc_id,
      patient_identifier_type('DDE person document id')
    ).first

    if patient
      patient.identifier('National id')&.void('NPID Reassigned')
      create_local_patient_identifier(patient, response['npid'], 'National id')
      patient.reload
    else
      patient = save_remote_patient(response)
    end

    patient
  end

  private

  def find_remote_patients_by_npid(npid)
    response, _status = dde_client.post('search_by_npid', npid: npid)

    unless response.class == Array
      raise "Patient search by failed: DDE Response => #{response}"
    end

    response
  end

  def find_remote_patients_by_name_and_gender(given_name, family_name, gender)
    response, _status = dde_client.post('search_by_name_and_gender', given_name: given_name,
                                                                     family_name: family_name,
                                                                     gender: gender)
    unless response.class == Array
      raise "Patient search by name and gender failed: DDE Response => #{response}"
    end

    response
  end

  def find_remote_patients_by_doc_id(doc_id)
    response, _status = dde_client.post('search_by_doc_id', doc_id: doc_id)

    unless response.class == Array
      raise "Patient search by doc_id failed: DDE Response => #{response}"
    end

    response
  end

  # Resolves local and remote patients and post processes the remote
  # patients to take on a structure similar to that of local
  # patients.
  def package_patients(local_patients, remote_patients)
    patients = resolve_patients(local_patients: local_patients, remote_patients: remote_patients)

    patients[:remotes] = patients[:remotes].collect { |patient| localise_remote_patient(patient) }

    patients
  end

  # Locally saves the first unresolved remote patient.
  #
  # Method internally calls resolve_patients on the passed arguments then
  # attempts to save the first unresolved patient in the local database.
  #
  # Returns: The imported patient (or nil if no local and remote patients are
  #          present).
  def import_remote_patient(local_patients, remote_patients)
    patients = resolve_patients(local_patients: local_patients, remote_patients: remote_patients)

    return patients[:locals].first if patients[:remotes].empty?

    save_remote_patient(patients[:remotes].first)
  end

  def link_local_to_dde_patient(local_patient, dde_patient)
    local_patient.identifier('DDE person document id')&.void("Assigned new id: #{dde_patient['doc_id']}")
    local_patient.identifier('National id')&.void("Assigned new id: #{dde_patient['npid']}")

    create_local_patient_identifier(local_patient, dde_patient['doc_id'], 'DDE person document id')
    create_local_patient_identifier(local_patient, dde_patient['npid'], 'National id')

    local_patient.reload
    local_patient
  end

  def create_local_patient_identifier(patient, value, type_name)
    identifier = PatientIdentifier.create(identifier: value,
                                          type: patient_identifier_type(type_name),
                                          location_id: Location.current.id,
                                          patient: patient)
    return identifier if identifier.errors.empty?

    raise "Could not save DDE identifier: #{type_name} due to #{identifier.errors.as_json}"
  end

  # Filters out @{param remote_patients} that exist in @{param local_patients}.
  #
  # Returns a hash with all resolved and unresolved remote patients:
  #
  #   { resolved: [..,], locals: [...], remotes: [...] }
  #
  # NOTE: All resolved patients are available in the local database
  def resolve_patients(local_patients:, remote_patients:)
    remote_patients = remote_patients.dup # Will be modifying this copy

    # Match all locals to remotes, popping out the matching patients from
    # the list of remotes. The remaining remotes are considered unresolved
    # remotes.
    resolved_patients = local_patients.each_with_object([]) do |local_patient, resolved_patients|
      # Local patient present on remote?
      remote_patient = remote_patients.detect do |patient|
        same_patient?(local_patient: local_patient, remote_patient: patient)
      end

      if remote_patient
        resolved_patients << local_patient
        remote_patients.delete(remote_patient)
      else
        resolved_patients << push_local_patient_to_dde(local_patient)
      end
    end

    { locals: resolved_patients, remotes: remote_patients }
  end

  # Matches local and remote patient
  def same_patient?(local_patient:, remote_patient:)
    local_npid = local_patient.identifier('National id')&.identifier
    local_doc_id = local_patient.identifier('DDE person document id')&.identifier

    return false unless local_npid && local_doc_id

    local_npid == remote_patient['npid'] && local_doc_id == remote_patient['doc_id']
  end

  # Saves local patient to DDE and links the two using the IDs
  # generated by DDE.
  def push_local_patient_to_dde(patient)
    response, status = dde_client.post('add_person', openmrs_to_dde_patient(patient))
    raise "Failed to create patient in DDE: #{response}" if status != 200

    link_local_to_dde_patient(patient, response)
  end

  # Converts a remote patient coming from DDE into a structure similar
  # to that of a local patient
  def localise_remote_patient(patient)
    Patient.new(
      patient_identifiers: localise_remote_patient_identifiers(patient),
      person: Person.new(
        names: localise_remote_patient_names(patient),
        addresses: localise_remote_patient_addresses(patient),
        birthdate: patient['birthdate'],
        birthdate_estimated: patient['birthdate_estimated'],
        gender: patient['gender']
      )
    )
  end

  def localise_remote_patient_identifiers(remote_patient)
    [PatientIdentifier.new(identifier: remote_patient['npid'],
                           type: patient_identifier_type('National ID')),
     PatientIdentifier.new(identifier: remote_patient['doc_id'],
                           type: patient_identifier_type('DDE Person Document ID'))]
  end

  def localise_remote_patient_names(remote_patient)
    [PersonName.new(given_name: remote_patient['given_name'],
                    family_name: remote_patient['family_name'],
                    middle_name: remote_patient['middle_name'])]
  end

  def localise_remote_patient_addresses(remote_patient)
    address = PersonAddress.new
    address.home_village = remote_patient['attributes']['home_village']
    address.home_traditional_authority = remote_patient['attributes']['home_traditional_authority']
    address.home_district = remote_patient['attributes']['home_district']
    address.current_village = remote_patient['attributes']['current_village']
    address.current_traditional_authority = remote_patient['attributes']['current_traditional_authority']
    address.current_district = remote_patient['attributes']['current_district']
    [address]
  end

  def dde_client
    return @dde_client if @dde_client

    @dde_client = DDEClient.new

    LOGGER.debug 'Searching for a stored DDE connection'
    if DDEService.connection
      LOGGER.debug 'Stored DDE connection found'
      @dde_client.connect(connection: DDEService.connection)
      return @dde_client
    end

    LOGGER.debug 'No stored DDE connection found... Loading config...'
    DDEService.connection = @dde_client.connect(config: config)
    @dde_client
  end

  def config
    app_config = YAML.load_file(DDE_CONFIG_PATH)
    {
      username: app_config['dde_username'],
      password: app_config['dde_password'],
      base_url: app_config['dde_url']
    }
  end

  # Converts an openmrs patient structure to a DDE person structure
  def openmrs_to_dde_patient(patient)
    LOGGER.debug "Converting OpenMRS person to dde_patient: #{patient}"
    person = patient.person

    person_name = person.names[0]
    person_address = person.addresses[0]
    person_attributes = filter_person_attributes(person.person_attributes)

    dde_patient = HashWithIndifferentAccess.new(
      given_name: person_name.given_name,
      family_name: person_name.family_name,
      gender: person.gender,
      birthdate: person.birthdate,
      birthdate_estimated: person.birthdate_estimated, # Convert to bool?
      attributes: {
        current_district: person_address ? person_address.state_province : nil,
        current_traditional_authority: person_address ? person_address.township_division : nil,
        current_village: person_address ? person_address.city_village : nil,
        home_district: person_address ? person_address.address2 : nil,
        home_village: person_address ? person_address.neighborhood_cell : nil,
        home_traditional_authority: person_address ? person_address.county_district : nil,
        occupation: person_attributes ? person_attributes[:occupation] : nil
      }
    )

    LOGGER.debug "Converted openmrs person to dde_patient: #{dde_patient}"
    dde_patient
  end

  # Convert a DDE person to an openmrs person.
  #
  # NOTE: This creates a person on the database.
  def save_remote_patient(dde_patient)
    LOGGER.debug "Converting DDE person to openmrs: #{dde_patient}"

    person = person_service.create_person(
      birthdate: dde_patient['birthdate'],
      birthdate_estimated: dde_patient['birthdate_estimated'],
      gender: dde_patient['gender']
    )

    person_service.create_person_name(
      person, given_name: dde_patient['given_name'],
              family_name: dde_patient['family_name'],
              middle_name: dde_patient['middle_name']
    )

    dde_patient_attributes = dde_patient['attributes']
    person_service.create_person_address(
      person, home_village: dde_patient_attributes['home_village'],
              home_traditional_authority: dde_patient_attributes['home_traditional_authority'],
              home_district: dde_patient_attributes['home_district'],
              current_village: dde_patient_attributes['current_village'],
              current_traditional_authority: dde_patient_attributes['current_traditional_authority'],
              current_district: dde_patient_attributes['current_district']
    )

    person_service.create_person_attributes(
      person, cell_phone_number: dde_patient_attributes['cellphone_number'],
              occupation: dde_patient_attributes['occupation']
    )

    patient = Patient.create(patient_id: person.id)
    link_local_to_dde_patient(patient, dde_patient)
  end

  def filter_person_attributes(person_attributes)
    return nil unless person_attributes

    person_attributes.each_with_object({}) do |attr, filtered|
      case attr.type.name.downcase.gsub(/\s+/, '_')
      when 'cell_phone_number'
        filtered[:cell_phone_number] = attr.value
      when 'occupation'
        filtered[:occupation] = attr.value
      when 'birthplace'
        filtered[:home_district] = attr.value
      when 'home_village'
        filtered[:home_village] = attr.value
      when 'ancestral_traditional_authority'
        filtered[:home_traditional_authority] = attr.value
      end
    end
  end

  def person_service
    PersonService.new
  end

  def patient_service
    PatientService.new
  end
end
