# frozen_string_literal: true

# LanguagesController: for language functionality
class LanguagesController < ApplicationController
  before_action :authenticate_user!

  # Returns all languagaes as an array of arrays where each inner is in the format
  # ['eng', 'English', supported: {sms: true, phone: true, email: true}]
  # Example Return: [["eng", "English", {}]...,["zho","Chinese", {}],["zul","Zulu", {}]]
  def language_data
    render json: Languages.all_languages
  end

  # Matches code to display name
  # params[:language_codes] must be a valid array of language codes (no nils or invalids)
  # Returns array of the display names for those codes
  # PARAM EXAMPLE: ['oci', 'tgk']
  # RETURN EXAMPLE: ['Occitan', 'Tajik']
  def translate_language_codes
    language_set_difference = params.require(:language_codes).map(&:to_sym) - Languages.all_languages.keys
    if language_set_difference.any?
      error_message = "There was an error looking up the following languages: #{language_set_difference.map(&:to_s)}"
      render(json: { error: error_message }, status: :unprocessable_entity) && return
    else
      render json: { display_names: params[:language_codes].map { |lang_code| Languages.all_languages[lang_code.to_sym][:display] } }
    end
  end
end
