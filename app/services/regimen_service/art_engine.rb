# frozen_string_literal: true

require 'set'

module RegimenService
  class ARTEngine
    def initialize(program:)
      @program = program
    end

    def find_regimens_by_weight(weight, paginator: nil)
      find_regimens weight: weight, age: nil, paginator: paginator
    end

    def find_regimens_by_age(age, paginator: nil)
      find_regimens age: age, weight: nil, paginator: paginator
    end

    def find_regimens(weight:, age:, paginator: nil)
      raise ArgumentError, 'weight or age expected' if weight.nil? && age.nil?

      ingredients = MohRegimenIngredient
      ingredients = ingredients.where 'min_weight <= ? and max_weight >= ?', weight, weight if weight
      ingredients = ingredients.where 'min_age <= ? and max_age >= ?', age, age if age
      ingredients = paginator.call ingredients if paginator

      categorise_regimens(regimens_from_ingredients(ingredients))
    end

    private

    # Packs a list of regimen ingredients into a map of
    # regimen id to regimens.
    #
    # NOTE: A regimen is just the following structure:
    #   {
    #     index: xx
    #     drug: {...},
    #     am: xx,
    #     pm: xx,
    #     category: xx
    #   }
    def regimens_from_ingredients(ingredients)
      ingredients.each_with_object({}) do |ingredient, regimens|
        regimen_index = ingredient.regimen.regimen_index
        regimen = regimens[regimen_index] || []

        regimen << ingredient_to_drug(ingredient)
        regimens[regimen_index] = regimen
        # add_category_to_regimen! regimen, ingredient
      end
    end

    def categorise_regimens(regimens)
      regimens.values.each_with_object({}) do |drugs, categorised_regimens|
        Rails.logger.debug "Interpreting drug list: #{drugs}"
        (0...(drugs.size - 1)).each do |i|
          ((i + 1)...(drugs.size)).each do |j|
            head = drugs[i...j]
            tail = [drugs[j]]

            trial_regimen = head + tail

            # regimen_name = regimen_interpreter(trial_regimen.map { |t| t[:drug_id] })
            regimen_name = classify_regimen_combo(trial_regimen.map { |t| t[:drug_id] })
            next unless regimen_name

            categorised_regimens[regimen_name] ||= []
            categorised_regimens[regimen_name] << trial_regimen

            # Avoid interpreting entire drug list twice at the end of the iteration:
            break if tail.empty?
          end
        end
      end
    end

    def ingredient_to_drug(ingredient)
      {
        drug_id: ingredient.drug.drug_id,
        drug_name: ingredient.drug.name,
        am: ingredient.dose.am,
        pm: ingredient.dose.pm
      }
    end

    def regimen_interpreter(medication_ids = [])
      Rails.logger.debug "Interpreting regimen: #{medication_ids}"
      regimen_name = nil

      REGIMEN_CODES.each do |regimen_code, data|
        data.each do |row|
          drugs = [row].flatten
          drug_ids = Drug.where(['drug_id IN (?)', drugs]).map(&:drug_id)
          if ((drug_ids - medication_ids) == []) && (drug_ids.count == medication_ids.count)
            regimen_name = regimen_code
            break
          end
        end
      end

      Rails.logger.warn "Failed to Interpret regimen: #{medication_ids}" unless regimen_name

      regimen_name
    end

    # An alternative to the regimen_interpreter method below...
    # This achieves the same as that method without hitting the database
    def classify_regimen_combo(drug_combo)
      Rails.logger.debug "Interpreting regimen: #{drug_combo}"

      drug_combo = Set.new drug_combo
      REGIMEN_CODES.each do |regimen_category, combos|
        combos.each { |combo| return regimen_category if combo == drug_combo }
      end

      Rails.logger.warn "Failed to Interpret regimen: #{drug_combo}"

      nil
    end

    REGIMEN_CODES = {
      # ABC/3TC (Abacavir and Lamivudine 60/30mg tablet) = 733
      # NVP (Nevirapine 50 mg tablet) = 968
      # NVP (Nevirapine 200 mg tablet) = 22
      # ABC/3TC (Abacavir and Lamivudine 600/300mg tablet) = 969
      # AZT/3TC/NVP (60/30/50mg tablet) = 732
      # AZT/3TC/NVP (300/150/200mg tablet) = 731
      # AZT/3TC (Zidovudine and Lamivudine 60/30 tablet) = 736
      # EFV (Efavirenz 200mg tablet) = 30
      # EFV (Efavirenz 600mg tablet) = 11
      # AZT/3TC (Zidovudine and Lamivudine 300/150mg) = 39
      # TDF/3TC/EFV (300/300/600mg tablet) = 735
      # TDF/3TC (Tenofavir and Lamivudine 300/300mg tablet = 734
      # ATV/r (Atazanavir 300mg/Ritonavir 100mg) = 932
      # LPV/r (Lopinavir and Ritonavir 100/25mg tablet) = 74
      # LPV/r (Lopinavir and Ritonavir 200/50mg tablet) = 73
      # Darunavir 600mg = 976
      # Ritonavir 100mg = 977
      # Etravirine 100mg = 978
      # RAL (Raltegravir 400mg) = 954
      # NVP (Nevirapine 200 mg tablet) = 22
      # LPV/r pellets = 979
      '0P' => [Set.new([733, 968]), Set.new([733, 22])],
      '0A' => [Set.new([969, 22]), Set.new([969, 968])],
      '2P' => [Set.new([732]), Set.new([732, 736]), Set.new([732, 39])],
      '2A' => [Set.new([731]), Set.new([731, 39]), Set.new([731, 736])],
      '4P' => [Set.new([736, 30]), Set.new([736, 11])],
      '4A' => [Set.new([39, 11]), Set.new([39, 30])],
      '5A' => [Set.new([735])],
      '6A' => [Set.new([734, 22])],
      '7A' => [Set.new([734, 932])],
      '8A' => [Set.new([39, 932])],
      '9P' => [Set.new([733, 74]), Set.new([733, 73]), Set.new([733, 979])],
      '9A' => [Set.new([969, 73]), Set.new([969, 74])],
      '10A' => [Set.new([734, 73])],
      '11P' => [Set.new([736, 74]), Set.new([736, 73])],
      '11A' => [Set.new([39, 73]), Set.new([39, 74])],
      '12A' => [Set.new([976, 977, 978, 954])]
    }.freeze
  end
end