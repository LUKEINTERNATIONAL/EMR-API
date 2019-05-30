# frozen_string_literal: true

class Api::V1::DispensationsController < ApplicationController
  def create
    dispensations, program_id = params.require(%i[dispensations program_id])

    program = Program.find(program_id)

    render json: DispensationService.create(program, dispensations), status: :created
  rescue InvalidParameterError => e
    render json: { errors: [e.getMessage, e.model_errors] }, status: :bad_request
  end

  def index
    patient_id = params.require %i[patient_id]

    obs_list = DispensationService.dispensations patient_id, params[:date]
    render json: paginate(obs_list)
  end

  def destroy
    dispensation = Observation.find(params[:id])
    service.void_dispensation(dispensation)

    render status: :no_content
  end

  private

  def service
    DispensationService
  end
end
