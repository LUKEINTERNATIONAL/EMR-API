Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Helper for creating dynamic redirect urls with redirect blocks
      def paginate_url(url, params)
        page = params[:page]
        page_size = params[:page_size]

        url += "&page=#{page}" if page
        url += "&page_size=#{page_size}" if page_size
        url
      end

      # Routes down here ... Best we move everything above into own modules

      resources :appointments
      resources :dispensations, only: %i[index create]
      resources :users do
        post '/activate', to: 'users#activate'
        post '/deactivate', to: 'users#deactivate'
      end

      # Not placed under users urls to allow crud on current user's roles
      resources :user_roles, only: %i[index create destroy]

      get '/people/_names' => 'person_names#index'
      resources :people do
        resources :person_relationships, path: :relationships

        get '/guardians', to: 'person_relationships#guardians'

        get('/names', to: redirect do |params, request|
          paginate_url "/api/v1/people/_names?person_id=#{params[:person_id]}",
                       request.params
        end)
      end

      resources :roles

      # Patients
      resources :patients do
        get '/labels/national_health_id' => 'patients#print_national_health_id_label'
        get '/labels/filing_number' => 'patients#print_filing_number'
        get '/visits' => 'patients#visits'
        get('/appointments', to: redirect do |params, request|
          paginate_url "/api/v1/appointments?patient_id=#{params[:patient_id]}",
                       request.params
        end)
        get '/drugs_received', to: 'patients#drugs_received'
        get '/last_drugs_received', to: 'patients#last_drugs_received'
        get '/current_bp_drugs', to: 'patients#current_bp_drugs'
        get '/last_bp_drugs_dispensation', to: 'patients#last_bp_drugs'
        get '/next_appointment_date', to: 'patient_appointments#next_appointment_date'
        get '/median_weight_height', to: 'patients#find_median_weight_and_height'
        get '/bp_trail', to: 'patients#bp_readings_trail'
        get '/eligible_for_htn_screening', to: 'patients#eligible_for_htn_screening'
        post '/filing_number', to: 'patients#assign_filing_number'
        get '/past_filing_numbers' => 'patients#filing_number_history'
        post '/npid', to: 'patients#assign_npid'
        post '/remaining_bp_drugs', to: 'patients#remaining_bp_drugs'
        post '/update_or_create_htn_state', to: 'patients#update_or_create_htn_state'
        resources :patient_programs, path: :programs
      end

      resources :patient_identifiers

      resources :concepts, only: %i[index show]

      # Locations
      resources :locations do
        get('/label', to: redirect do |params, request|
          "/api/v1/labels/location?location_id=#{params[:location_id]}"
        end)
      end

      resources :regions, only: %i[index] do
        get('/districts', to: redirect do |params, request|
          paginate_url "/api/v1/districts?region_id=#{params[:region_id]}", request.params
        end)
      end

      resources :districts, only: %i[create index] do
        get('/traditional_authorities', to: redirect do |params, request|
          redirect_url = "/api/v1/traditional_authorities?district_id=#{params[:district_id]}"
          paginate_url redirect_url, request.params
        end)
      end

      resources :traditional_authorities, only: %i[create index] do
        get('/villages', to: redirect do |params, request|
          redirect_url = "/api/v1/villages?traditional_authority_id=#{params[:traditional_authority_id]}"
          paginate_url redirect_url, request.params
        end)
      end

      resources :villages, only: %i[create index]

      get '/encounters/_types' => 'encounter_types#index'
      resources :encounters do
        get('/observations', to: redirect do |params, request|
          redirect_url = "/api/v1/observations?encounter_id=#{params[:encounter_id]}"
          paginate_url redirect_url, request.params
        end)
      end

      resources :observations

      resources :programs do
        resources :program_workflows, path: :workflows
        resources :program_regimens, path: :regimens
        get 'pellets_regimen' => 'program_regimens#pellets_regimen'
        get 'next_available_arv_number' => 'program_patients#find_next_available_arv_number'
        get 'lookup_arv_number/:arv_number' => 'program_patients#lookup_arv_number'
        get 'regimen_starter_packs' => 'program_regimens#find_starter_pack'
        get 'custom_regimen_ingredients' => 'program_regimens#custom_regimen_ingredients'
        get 'defaulter_list' => 'program_patients#defaulter_list'
        resources :program_patients, path: :patients do
          get '/last_drugs_received' => 'program_patients#last_drugs_received'
          get '/dosages' => 'program_patients#find_dosages'
          get '/status' => 'program_patients#status'
          get '/earliest_start_date' => 'program_patients#find_earliest_start_date'
          get '/labels/visits', to: 'program_patients#print_visit_label'
          get '/labels/history', to: 'program_patients#print_history_label'
          get '/labels/lab_results', to: 'program_patients#print_lab_results_label'
          get '/labels/transfer_out', to: 'program_patients#print_transfer_out_label'
          get '/labels/patient_history', to: 'program_patients#print_patient_history_label'
          get '/mastercard_data', to: 'program_patients#mastercard_data'
          #ANC
          get '/surgical_history', to: 'program_patients#surgical_history'
          get '/anc_visit', to: 'program_patients#anc_visit'
          get '/art_hiv_status', to: 'program_patients#art_hiv_status'
          get '/subsequent_visit', to: 'program_patients#subsequent_visit'
          get '/saved_encounters', to: 'program_patients#saved_encounters'
          resources :patient_states, path: :states
        end
        resources :lab_test_types, path: 'lab_tests/types'
        get '/lab_tests/panels' => 'lab_test_types#panels' # TODO: Move this into own controller
        resources :lab_test_orders, path: 'lab_tests/orders'
        resources :lab_test_results, path: 'lab_tests/results'
        post '/lab_tests/order_and_results' => 'lab_test_results#create_order_and_results'
        get '/lab_tests/locations' => 'lab_test_orders#locations'
        get '/lab_tests/labs' => 'lab_test_orders#labs'
        get '/lab_tests/orders_without_results' => 'lab_test_orders#orders_without_results'
        get '/lab_tests/measures' => 'lab_test_types#measures'
        resources :program_reports, path: 'reports'
      end

      resources :stock
      post '/edit_stock_report', to: 'stock#edit'

      namespace :types do
        resources :relationships
        resources :lab_tests
        resources :patient_identifiers
      end

      resources :drugs do
        get '/barcode', to: 'drugs#print_barcode'
      end

      resources :drug_orders
      resources :orders
      get '/drug_sets', to: 'drugs#drug_sets' # ANC get drug sets

      resource :global_properties
      resource :user_properties

      resource :session_stats, path: 'stats/session'

      # Workflow engine
      get '/workflows/:program_id/:patient_id' => 'workflows#next_encounter'

      get '/current_time', to: 'time#current_time'

      get '/dde/patients/find_by_npid', to: 'dde#find_patients_by_npid'
      get '/dde/patients/find_by_name_and_gender', to: 'dde#find_patients_by_name_and_gender'
      get '/dde/patients/import_by_doc_id', to: 'dde#import_patients_by_doc_id'
      get '/dde/patients/import_by_name_and_gender', to: 'dde#import_patients_by_name_and_gender'
      get '/dde/patients/import_by_npid', to: 'dde#import_patients_by_npid'
      get '/dde/patients/match_by_demographics', to: 'dde#match_patients_by_demographics'
      post '/dde/patients/reassign_npid', to: 'dde#reassign_patient_npid'
      post '/dde/patients/merge', to: 'dde#merge_patients'

      get '/labels/location', to: 'locations#print_label'

      # Search
      get '/search/given_name' => 'person_names#search_given_name'
      get '/search/middle_name' => 'person_names#search_middle_name'
      get '/search/family_name' => 'person_names#search_family_name'
      get '/search/people' => 'people#search'
      get '/search/patients/by_npid' => 'patients#search_by_npid'
      get '/search/patients/by_identifier' => 'patients#search_by_identifier'
      get '/search/patients' => 'patients#search_by_name_and_gender'
      get '/search/properties' => 'properties#search'
      get '/search/landmarks' => 'landmarks#search'

      get '/dde/patients/find_by_npid', to: 'dde#find_patients_by_npid'
      get '/dde/patients/find_by_name_and_gender', to: 'dde#find_patients_by_name_and_gender'
      get '/dde/patients/import_by_doc_id', to: 'dde#import_patients_by_doc_id'
      get '/dde/patients/import_by_name_and_gender', to: 'dde#import_patients_by_name_and_gender'
      get '/dde/patients/import_by_npid', to: 'dde#import_patients_by_npid'
      get '/dde/patients/match_by_demographics', to: 'dde#match_patients_by_demographics'
      post '/dde/patients/reassign_npid', to: 'dde#reassign_patient_npid'
      post '/dde/patients/merge', to: 'dde#merge_patients'

      post '/reports/encounters' => 'encounters#count'
    end
  end

  root to: 'static#index'
  get '/api/v1/archiving_candidates' => 'api/v1/patients#find_archiving_candidates'
  get '/api/v1/_health' => 'healthcheck#index'
  post '/api/v1/auth/login' => 'api/v1/users#login'
  post '/api/v1/auth/verify_token' => 'api/v1/users#check_token_validity'
  get '/api/v1/fast_track_assessment' => 'api/v1/fast_track#assessment'
  post '/api/v1/cancel_fast_track' => 'api/v1/fast_track#cancel'
  get '/api/v1/on_fast_track' => 'api/v1/fast_track#on_fast_track'
  get '/api/v1/patient_weight_for_height_values' => 'api/v1/weight_for_height#index'
  get '/api/v1/booked_appointments' => 'api/v1/patient_appointments#booked_appointments'
  get '/api/v1/concept_set' => 'api/v1/concept_sets#show'
  get '/api/v1/cervical_cancer_screening' => 'api/v1/cervical_cancer_screening#show'

  get '/api/v1/dashboard_stats' => 'api/v1/reports#index'

  # SQA controller
  get '/api/v1/dead_encounters' => 'api/v1/cleaning#index'
  get '/api/v1/date_enrolled' => 'api/v1/cleaning#dateEnrolled'
  get '/api/v1/start_date' => 'api/v1/cleaning#startDate'
  get '/api/v1/male' => 'api/v1/cleaning#male'
  get '/api/v1/incomplete_visits' => 'api/v1/cleaning#incompleteVisits'

  #OPD reports
  get '/api/v1/diagnosis' => 'api/v1/reports#diagnosis'
  get '/api/v1/registration' => 'api/v1/reports#registration'
  get '/api/v1/diagnosis_by_address' => 'api/v1/reports#diagnosis_by_address'
  get '/api/v1/with_nids' => 'api/v1/reports#with_nids'
  get '/api/v1/drugs_given_without_prescription' => 'api/v1/reports#drugs_given_without_prescription'
  get '/api/v1/drugs_given_with_prescription' => 'api/v1/reports#drugs_given_with_prescription'

  get '/api/v1/cohort_report_raw_data' => 'api/v1/reports#cohort_report_raw_data'
  get '/api/v1/cohort_disaggregated' => 'api/v1/reports#cohort_disaggregated'
  get '/api/v1/cohort_survival_analysis' => 'api/v1/reports#cohort_survival_analysis'
end
