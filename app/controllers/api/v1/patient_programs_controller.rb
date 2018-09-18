class Api::V1::PatientProgramsController < ApplicationController
  def index
    render json: PatientProgram.where(patient_id: params[:patient_id])
  end

  def create
    create_params = params.require(:patient_program).permit(:program_id, :date_enrolled)
    create_params[:date_enrolled] ||= Time.now
    create_params[:location_id] = Location.current.id
    create_params[:patient_id] = params[:patient_id]

    p_program = PatientProgram.create create_params

    if p_program.errors.empty?
      render json: p_program, status: :created
    else
      render json: p_program.errors, status: :bad_request
    end
  end

  def destroy
    p_program = PatientProgram.find_by patient_id: params[:patient_id],
                                       program_id: params[:program_id]

    unless p_program
      render json: { errors: ['Not found'] }, status: :not_found
      return
    end

    if p_program.destroy
      render status: :no_content
    else
      render json: :p_program.errors, status: :internal_server_error
    end
  end
end