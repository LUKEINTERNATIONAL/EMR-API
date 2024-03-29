# frozen_string_literal: true

module ANCService
  # Patients sub service.
  #
  # Basically provides ANC specific patient-centric functionality
  class PatientsEngine
    include ModelUtils

    ART_PROGRAM =  Program.find_by name: 'HIV PROGRAM'
    ARV_NUMBER = PatientIdentifierType.find_by name: 'ARV Number'
  
    def initialize(program:)
      @program = program
    end
  
    # Retrieves given patient's status info.
    #
    # The info is just what you would get on a patient information
    # confirmation page in an ANC application.
    def patient(patient_id, date)
      patient_summary(Patient.find(patient_id), date).full_summary
    end

    def visit_summary_label(patient, date)
      ANCService::PatientVisitLabel.new patient, date
    end

    def history_label(patient, date)
      ANCService::PatientHistoryLabel.new patient, date
    end

    def lab_results_label(patient, date)
      ANCService::PatientLabLabel.new patient, date
    end

    def gravida(patient, date)

      gravida = patient.encounters.joins(:observations)
          .where(["DATE(encounter_datetime) >= ? AND DATE(encounter_datetime) <= ? 
            AND encounter_type = ? AND obs.concept_id = ?", (date.to_date - 4.months),
            date,EncounterType.find_by_name("OBSTETRIC HISTORY").id,
            ConceptName.find_by_name("Patient pregnant").concept_id]).order("encounter_datetime DESC")
          .first.observations.collect{|o|
            o.value_numeric
          }.compact rescue 0
          
      return gravida[0] unless gravida == 0
    end

    def anc_visit(patient, date)
      @visit = []
      last_lmp = date_of_lnmp(patient)

      unless last_lmp.blank?

        @visit =  patient.encounters.where(["DATE(encounter_datetime) >= ? 
            AND DATE(encounter_datetime) <= ? AND encounter_type = ?",
            last_lmp, date,EncounterType.find_by_name("ANC VISIT TYPE")]).collect{|e|
              e.observations.collect{|o|
                o.answer_string.to_i if o.concept.concept_names.first.name.downcase == "reason for visit"
                }.compact
            }.flatten rescue []

      end

      return {"visit_number": @visit, "gravida": gravida(patient, date)}

    end

    def surgical_history(patient, date)
      {hysterectomy: hysterectomy(patient)}
    end

    def saved_encounters(patient, date)
      last_lmp = date_of_lnmp(patient)
      ontime_encounters = ["REGISTRATION", "SOCIAL HISTORY", "SURGICAL HISTORY",
        "OBSTETRIC HISTORY", "MEDICAL HISTORY", "CURRENT PREGNANCY"]

      x = Encounter.where(["DATE(encounter_datetime) = ? AND patient_id = ? AND voided = 0",
          date.to_date.strftime("%Y-%m-%d"),patient.patient_id]).collect{|e| e.name}.uniq

      if(last_lmp.blank?)

        x.delete("TREATMENT") unless patient_given_drugs_today(patient, date)

        return x

      else

        y = Encounter.where(["DATE(encounter_datetime) >= ? AND DATE(encounter_datetime) < ? 
          AND patient_id = ? and voided = 0", last_lmp.to_date.strftime("%Y-%m-%d"),
          date.to_date.strftime("%Y-%m-%d"),patient.patient_id]).collect{|e| 
          e.name if ontime_encounters.include?(e.name)
      }.uniq

      z = (x + y).compact

      z.delete("TREATMENT") unless patient_given_drugs_today(patient, date)

      return z

      end
    end

    def hysterectomy(patient)

      hysterectomy_conditions = ConceptName.where("name like '%hysterectomy%'").collect{|c| c.concept_id}

      value = patient.encounters.joins([:observations]).where(["encounter_type = ? 
        AND obs.concept_id in (?) AND obs.value_coded = ?", 
        EncounterType.find_by_name("SURGICAL HISTORY").id,
        hysterectomy_conditions, ConceptName.find_by_name("Yes").concept_id
        ]).last
      
      unless value.blank?
        return true
      end

      return false
    end

    def art_hiv_status(patient)

      hiv_positive = PatientProgram.find_by_sql("SELECT pg.patient_id 
        FROM patient_program pg
        WHERE pg.patient_id = #{patient.patient_id} 
        AND pg.program_id = #{ART_PROGRAM.id}")

      if !hiv_positive.blank?
        hiv_status = 'Positive'
        query = "SELECT pg.date_enrolled, s2.start_date, s2.state  
            FROM patient_program
            INNER JOIN patient_state s2 ON s2.patient_state_id = s2.patient_state_id 
						AND pg.patient_program_id = s2.patient_program_id
						AND s2.patient_state_id = (
              SELECT MAX(s3.patient_state_id) FROM patient_state s3
							WHERE s3.patient_state_id = s2.patient_state_id)
            AND pg.voided = 0 AND pg.patient_id = '#{patient.patient_id}' 
            AND s2.state = 7 ORDER BY s2.start_date ASC LIMIT 1"

				art_start_date = PatientProgram.find_by_sql(query).first.date_enrolled.to_date.to_s(:db) rescue nil

        on_art = 'Yes' if art_start_date.present?

        if (on_art.downcase == 'yes')

          arv_number = PatientIdentifier.find_by_sql("SELECT pi.identifier 
            FROM patient_identifier pi
            WHERE pi.identifier_type = #{ARV_NUMBER.id} 
              AND pi.patient_id = '#{patient.patient_id}'
            ORDER BY pi.date_created DESC LIMIT 1")[0]['identifier']

        end rescue nil

      end

      return {hiv_status: hiv_status, art_status: on_art, arv_number: arv_number, arv_start_date: art_start_date}

    end

    def subsequent_visit(patient)
      anc_visit = false
      preg_test = false

      lmp_date = date_of_lnmp(patient)
      return {subsequent_visit: false, pregnancy_test: false} if lmp_date.nil?

      unless lmp_date.nil?
        visit_type = EncounterType.find_by name: "ANC VISIT TYPE"
        reason_for_visit = ConceptName.find_by name: "Reason for visit"

        visit = Encounter.joins(:observations).where("encounter.encounter_type = ?
            AND concept_id = ? AND encounter.patient_id = ? AND 
            DATE(encounter.encounter_datetime) >= DATE(?)",
            visit_type.id, reason_for_visit.concept_id, 
            patient.patient_id, lmp_date)
          .order(encounter_datetime: :desc).first.blank?

        unless visit
          anc_visit = true
          preg_test = pregnancy_test_done?(patient, lmp_date)
          prev_hiv_test = previous_hiv_test_results(patient, lmp_date)
        end
      end

      return {subsequent_visit: anc_visit, pregnancy_test: preg_test, hiv_status: prev_hiv_test}
    end

    # Verifies if the last visit patient undergo pregnancy test
    def pregnancy_test_done?(patient, checked_date)

      lab_encounter   = EncounterType.find_by_name("LAB RESULTS")
      pregnancy_test  = ConceptName.find_by_name("Pregnancy test")
      yes_concept     = ConceptName.find_by_name("Yes")

      last_test_visit = patient.encounters.joins([:observations])
        .where(["encounter.encounter_type = ? AND (obs.concept_id = ?) 
          AND encounter.encounter_datetime > ? AND e.voided = 0", 
          lab_encounter.id, 
          pregnancy_test.concept_id,checked_date.to_date])
        .order([:encounter_datetime])
        .select("value_coded")
        .last.value_coded rescue nil
  
      if last_test_visit == yes_concept.concept_id
        return true
      end

      return false

    end

    # Check previous hiv test results

    def previous_hiv_test_results(patient, checked_date)

      current_status =  ConceptName.find_by name:'HIV Status'
      prev_hiv_status = ConceptName.find_by name: 'Previous HIV Test Results'

      prev_test_done = Observation.where( person: patient.person, concept: concept('Previous HIV Test Done'))\
          .order(obs_datetime: :desc)\
          .first\
          &.value_coded || nil
      
      if (prev_test_done == 1065) #if value is Yes, check prev hiv status

        prev_hiv_test_res = Observation.where(["person_id = ? and concept_id = ? and obs_datetime > ?",
            patient.patient_id, prev_hiv_status.concept_id, checked_date])\
          .order(obs_datetime: :desc)\
          .first\
          &.value_coded

        prev_status = ConceptName.find_by_concept_id(prev_hiv_test_res).name

        return prev_status.to_s if prev_status.to_s.downcase == 'positive'
      
      end

      hiv_test_res =  Observation.where(["person_id = ? and concept_id = ? and obs_datetime > ?",
          patient.person.id, current_status.concept_id, checked_date])\
        .order(obs_datetime: :desc)\
        .first\
        &.value_coded rescue nil

        hiv_status = ConceptName.find_by_concept_id(hiv_test_res).name rescue nil
        
        hiv_status ||= prev_status

        return hiv_status 
    end

    private

    def patient_summary(patient, date)
      PatientSummary.new patient, date
    end

    def date_of_lnmp(patient)
      lmp = ConceptName.find_by name: "Last menstrual period"
      current_pregnancy = EncounterType.find_by name: "CURRENT PREGNANCY"

      last_lmp = patient.encounters.joins([:observations])
        .where(['encounter_type = ? AND obs.concept_id = ?',
          current_pregnancy.id,lmp.concept_id])
        .last.observations.collect { 
          |o| o.value_datetime 
        }.compact.last.to_date rescue nil
    end

    # Check if patient has been given drugs 
    # apart from TTV drugs.

    def patient_given_drugs_today(patient, date)

      ttv_drug = Drug.find_by name: "TTV (0.5ml)"
      drugs = []

      drug_order = ActiveRecord::Base.connection.select_all(
        "SELECT drug_order.drug_inventory_id FROM encounter INNER JOIN orders 
          ON orders.encounter_id = encounter.encounter_id 
          AND orders.voided = 0 
        INNER JOIN drug_order ON drug_order.order_id = orders.order_id 
        WHERE encounter.voided = 0 
        AND (encounter.patient_id = #{patient.patient_id} 
          AND DATE(encounter.encounter_datetime) = DATE('#{date}')) 
          ORDER BY encounter.encounter_datetime DESC"
      ).rows.collect{|d| drugs << d[0]}.compact
      
      drugs.delete(ttv_drug.id)

      if drugs.length > 0
        return true
      else
        return false
      end

    end
    
  end

end
