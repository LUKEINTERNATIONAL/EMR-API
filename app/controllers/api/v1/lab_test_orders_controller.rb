# frozen_string_literal: true

class Api::V1::LabTestOrdersController < ApplicationController
  def index
    if params[:accession_number]
      orders = engine.find_orders_by_accession_number params[:accession_number]
      render json: paginate(orders)
    elsif params[:patient_id]
      patient = Patient.find params[:patient_id]
      orders = engine.find_orders_by_patient patient
      # NOTE: orders can't be paginated here as it is just an ordinary array
      # not a queryset
      render json: orders
    else
      render json: { errors: ['accession_number or patient_id required'] },
             status: :bad_request
    end
  end

  def create
    lab_test_type_id, encounter_id = params.require %i[test_type_id encounter_id]

    begin
      date = params[:date] ? params[:date].to_date : nil
    rescue ArgumentError => e
      error = "Failed to parse date(#{params[:date]}): #{e}"
      return render json: { errors: [error] }, status: :bad_request
    end

    type = LabTestType.find lab_test_type_id
    encounter = Encounter.find encounter_id
    order = engine.create_order type: type, encounter: encounter, date: date

    render json: order, status: :created
  end

  private

  def engine
    # TODO: Access the engine from a factory not directly like this
    @engine ||= ARTService::LabTestsEngine.new program: nil
  end
end
