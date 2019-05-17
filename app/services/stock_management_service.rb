# frozen_string_literal: true

class StockManagementService
  include ParameterUtils

  # Pharmacy activities (these map to pharmacy_encounter_type.name in the db)
  STOCK_ADD = 'New deliveries'
  STOCK_EDIT = 'Edited stock'
  STOCK_DEBIT = 'Tins removed'

  # Pharmacy activity properties
  REALLOCATION_DESTINATION = 'Transfer out to location'
  REALLOCATION_DRUG = 'Drug getting reallocated'

  # Add list of drugs to stock
  #
  # @param{batch_number} A batch number that came with the drugs package
  # @param{drugs} A list of structures (hashes) containing the stock items
  #               (see description below for the stock item structure).
  #
  # Inventory item structure:
  #       {
  #         drug_id: *integer      # drug_id from Drug model
  #         quantity: *double      # Amount of drugs brought in terms of the drugs atomic unit (eg pills)
  #         expiry_date: *string   # A date conforming to ISO 8601 (ie YYYY-MM-DD)
  #         delivery_date: string  # Similar to above but is not required (defaults to today if not specified)
  #       }
  def add_items_to_batch(batch_number, stock_items)
    ActiveRecord::Base.transaction do
      batch = find_or_create_batch(batch_number)

      stock_items.each_with_index do |item, i|
        drug_id = fetch_parameter(item, :drug_id)
        quantity = fetch_parameter(item, :quantity)

        delivery_date = fetch_parameter_as_date(item, :delivery_date, Date.today)
        expiry_date = fetch_parameter_as_date(item, :expiry_date)

        item = create_batch_item(batch, drug_id, quantity, delivery_date, expiry_date)
        validate_activerecord_object(item)
      rescue StandardError => e
        raise e.class, "Failed to parse stock item ##{i} due to `#{e.message}`"
      end

      batch
    end
  end

  # Returns an ActiveRecord queryset for retrieving batches on record
  def find_all_batches
    PharmacyBatch.order(date_created: :desc)
  end

  def find_batch_by_batch_number(batch_number)
    batch = PharmacyBatch.find_by_batch_number(batch_number)
    raise NotFoundError, "Batch ##{batch_number} does not exist" unless batch

    batch
  end

  def find_batch_item_by_id(id)
    PharmacyBatchItem.find(id)
  end

  def find_batch_items(filters = {})
    query = PharmacyBatchItem
    query = query.where(filters) unless filters.empty?
    query.order(Arel.sql('date_created DESC, expiry_date ASC'))
  end

  def void_batch(batch_number, reason)
    batch = find_batch_by_batch_number(batch_number)
    batch.items.each { |item| item.void(reason) }
    batch.void(reason)
  end

  def update_batch_item(batch_item_id, params)
    item = PharmacyBatchItem.find(batch_item_id)
    item.update(params)
    # create_stock_transaction(item, quantity, STOCK_EDIT, Date.today)
  end

  def void_batch_item(batch_item_id, reason)
    item = PharmacyBatchItem.find(batch_item_id)
    item.void(reason)
  end

  def find_earliest_expiring_item(filters = {})
    item = PharmacyBatchItem.where(filters).order(expiry_date: :asc).first
    raise NotFoundError, 'No items found' unless item

    item
  end

  def reallocate_items(reallocation_code, batch_item_id, quantity, destination_location_id)
    ActiveRecord::Base.transaction do
      item = PharmacyBatchItem.find(batch_item_id)
      quantity = quantity.abs

      commit_transaction(item, STOCK_EDIT, -quantity)

      destination = Location.find(destination_location_id)

      PharmacyBatchItemReallocation.create(reallocation_code: reallocation_code, item: item,
                                           quantity: quantity, location: destination)
    end
  end

  private

  def find_or_create_batch(batch_number)
    batch = PharmacyBatch.find_by_batch_number(batch_number)
    return batch if batch

    PharmacyBatch.create(batch_number: batch_number)
  end

  def create_batch_item(batch, drug_id, quantity, delivery_date, expiry_date)
    PharmacyBatchItem.create(
      batch: batch,
      drug_id: drug_id,
      delivered_quantity: quantity,
      current_quantity: 0,
      delivery_date: delivery_date,
      expiry_date: expiry_date
    )
  end

  def create_pharmacy_event(activity_name, date = nil)
    date ||= Date.today
    type = PharmacyActivityType.find_by_name(activity_name)
    raise "Invalid pharmacy activity name: #{activity_name}" unless type

    PharmacyActivity.create(type: type, date: date)
  end

  def commit_transaction(batch_item, event_name, quantity, date = nil)
    ActiveRecord::Base.transaction do
      date ||= Date.today

      event = validate_activerecord_object(
        Pharmacy.create(item: batch_item, value_numeric: quantity,
                        type: pharmacy_event_type(event_name),
                        encounter_date: date)
      )

      batch_item.current_quantity += quantity

      if batch_item.current_quantity.negative?
        raise InvalidParameterError, "Quantity (#{quantity}) exceeds current quantity on item ##{batch_item.id}"
      end

      batch_item.save
      validate_activerecord_object(batch_item)

      { event: event, target_item: batch_item }
    end
  end

  def add_pharmacy_activity_property(activity, property_name, values)
    concept_id = ConceptName.find_by_name(property_name)
    PharmacyActivityProperty.create(activity: activity, concept_id: concept_id, **values)
  end

  def add_stock_item_quantity(stock_item_id, quantity)
    stock_item = PharmacyStockItem.find(stock_item_id)
    stock_item.quantity += quantity

    if stock_item.quantity.negative?
      raise InvalidParameterError, 'Chosen quantity exceeds available quantity'
    end

    stock_item.save
    stock_item
  end

  def pharmacy_event_type(event_name)
    type = PharmacyEncounterType.find_by_name(event_name)
    raise NotFoundError, "Pharmacy encounter type not found: #{event_name}" unless type

    type
  end

  def validate_activerecord_object(object)
    return object if object.errors.empty?

    error = InvalidParameterError.new('Failed to create or save object due to bad parameters')
    error.model_errors = object.errors
    raise error
  end
end
