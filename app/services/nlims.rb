# frozen_string_literal: true

require 'ostruct'
require 'rest-client'

class NLims
  def initialize(config)
    @api_prefix = config['lims_prefix'] || 'v1'
    @api_protocol = config['lims_protocol'] || 'http'
    @api_host = config['lims_host']
    @api_url = config['lims_url']
    @api_port = config['lims_port']
    @connection = nil
  end

  # We initially require a temporary authentication for user creation.
  # All other requests must start with an auth
  def temp_auth(username, password)
    response = get "authenticate/#{username}/#{password}"

    @connection = OpenStruct.new token: response['token']
  end

  def auth(username, password)
    response = get "re_authenticate/#{username}/#{password}"

    @connection = OpenStruct.new token: response['token']
  end

  def legacy_order_test(patient, order)
    patient_name = patient.person.names.first
    user_name = User.current.person.names.first
    sample_type = order['sample_type']
    tests = [order['test_name']]
    reason_for_test = order['reason_for_test']
    sample_status = order['sample_status']

    post 'create_order', district: 'Unknown',
                         health_facility_name: Location.current.name,
                         first_name: patient_name.given_name,
                         last_name: patient_name.family_name,
                         middle_name: patient_name.middle_name,
                         date_of_birth: patient.person.birthdate,
                         gender: patient.person.gender,
                         national_patient_id: patient.national_id,
                         phone_number: '',
                         who_order_test_last_name: user_name.family_name,
                         who_order_test_first_name: user_name.given_name,
                         who_order_test_id: User.current.id,
                         order_location: 'ART',
                         sample_type: sample_type,
                         tests: tests,
                         date_sample_drawn: order['date_sample_drawn'],
                         sample_priority: reason_for_test,
                         sample_status: sample_status,
                         art_start_date: 'unknown',
                         requesting_clinician: '',
                         target_lab: Location.current.name
  end

  def order_test(patient:, user:, test_type:, date:, reason:, requesting_clinician:)
    patient_name = patient.person.names.first
    user_name = user.person.names.first

    temp_prefix = @api_prefix
    @api_prefix = 'api/v2'

    response = post 'request_order', district: 'Unknown',
                                     health_facility_name: Location.current.name,
                                     first_name: patient_name.given_name,
                                     last_name: patient_name.family_name,
                                     middle_name: '',
                                     date_of_birth: patient.person.birthdate,
                                     gender: patient.person.gender,
                                     national_patient_id: patient.national_id,
                                     phone_number: '',
                                     who_order_test_last_name: user_name.family_name,
                                     who_order_test_first_name: user_name.given_name,
                                     who_order_test_id: user.id,
                                     order_location: 'ART',
                                     date_sample_drawn: date,
                                     tests: test_type,
                                     sample_priority: reason,
                                     art_start_date: 'unknown',
                                     requesting_clinician: requesting_clinician

    @api_prefix = temp_prefix

    response
  end

  def patient_results(accession_number)
    get("query_results_by_tracking_number/#{accession_number}")
  end

  def all_results(patient)
    get("query_results_by_npid/#{patient.national_id}")
  end

  def patient_orders(accession_number)
    get("query_order_by_tracking_number/#{accession_number}")
  end

  def all_orders(patient)
    get("query_order_by_npid/#{patient.national_id}")
  end

  def specimen_types(test_type)
    tests[test_type]
  end

  def test_types
    tests.keys.sort
  end

  def locations
    get('retrieve_order_location')
  end

  def labs
    get('retrieve_target_labs')
  end

  # Call temp_auth before this
  def create_user(body)
    post 'create_user', body
  end

  def tests_without_results(npid)
    get("query_tests_with_no_results_by_npid/#{npid}")
  end

  def test_measures(test_name)
    test_name.gsub!(/\s+/, '_')
    get("query_test_measures/#{test_name}")
  end

  def update_test(values)
    post('update_test', values)
  end

  private

  def tests
    @tests ||= get('retrieve_test_Catelog')
  end

  def get(path)
    exec_request(path) do |full_path, headers|
      RestClient.get(full_path, headers)
    end
  end

  def post(path, body)
    exec_request(path) do |full_path, headers|
      RestClient.post(full_path, body.as_json, headers)
    end
  end

  def exec_request(path)
    response = yield expand_url(path), token: @connection&.token,
                                       content_type: 'application/json'

    response = JSON.parse(response)
    if response['error'] == true
      raise LimsError, "Failed to communicate with LIMS: #{response['message']}"
    end

    response['data']
  end

  def expand_url(path)
    "#{@api_protocol}://#{@api_host}:#{@api_port}/#{@api_prefix}/#{path}"
  end
end
