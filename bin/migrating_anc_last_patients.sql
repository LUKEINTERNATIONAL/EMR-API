SET foreign_key_checks = 0;
/* the defaults */
SET @max_encounter_id := (SELECT max(encounter_id) FROM openmrs_area18_art.encounter);
SET @max_patient_id := (SELECT max(person_id) FROM openmrs_area18_art.person);
SET @max_patient_program_id := (SELECT max(patient_program_id) from openmrs_area18_art.patient_program);
SET @max_order_id := (SELECT max(order_id) from openmrs_area18_art.orders);
SET @max_obs_id := (SELECT max(obs_id) FROM openmrs_area18_art.obs);

/* dropping and creating person_back_up  */
DROP table IF EXISTS openmrs_area18_anc.anc_last_patients_to_be_migrated;

create table openmrs_area18_anc.anc_last_patients_to_be_migrated as
SELECT (@max_patient_id + patient_id) AS ART_patient_id, patient_id AS ANC_patient_id, family_name, given_name, identifier, gender, birthdate FROM openmrs_area18_anc.anc_remaining_patient
WHERE identifier NOT IN (SELECT anc_d.identifier FROM openmrs_area18_anc.anc_remaining_diff_gender anc_d)
AND identifier NOT IN (SELECT ART_identifier FROM openmrs_area18_anc.anc_art_patients_with_voided_art_identifier WHERE pi_voided = 1 AND void_reason LIKE '%new ID:%');

/* The first query is inserting BDE person table into main person table minus the users  */
INSERT INTO openmrs_area18_art.person (person_id, gender, birthdate, birthdate_estimated, dead, death_date, cause_of_death, creator, date_created, changed_by, date_changed, voided, voided_by, date_voided, void_reason, uuid)
select pp.ART_patient_id, p.gender, p.birthdate, p.birthdate_estimated, p.dead, p.death_date, p.cause_of_death, c.ART_user_id, p.date_created, u.ART_user_id, p.date_changed, p.voided, p.voided_by, p.date_voided, p.void_reason, (select uuid()) 
from openmrs_area18_anc.person p 
 inner join openmrs_area18_anc.anc_last_patients_to_be_migrated pp ON pp.ANC_patient_id = p.person_id and p.voided = 0
 left join openmrs_area18_anc.user_bak c on c.ANC_user_id = p.creator
 left join openmrs_area18_anc.user_bak u on u.ANC_user_id = p.changed_by;

/* This query insert BDE person_name table into main person_name table minus the users  */
INSERT INTO openmrs_area18_art.person_name (preferred, person_id, prefix, given_name, middle_name, family_name_prefix, family_name, family_name2, family_name_suffix, degree, creator, date_created, voided, voided_by, date_voided, void_reason, changed_by, date_changed, uuid)
select p.preferred, pp.ART_patient_id, p.prefix, p.given_name, p.middle_name, p.family_name_prefix, p.family_name, p.family_name2, p.family_name_suffix, p.degree, c.ART_user_id, p.date_created, p.voided,  p.voided_by, p.date_voided, p.void_reason,  u.ART_user_id, p.date_changed, (select uuid())
from openmrs_area18_anc.person_name p 
	inner join openmrs_area18_anc.anc_last_patients_to_be_migrated pp ON pp.ANC_patient_id = p.person_id and p.voided  = 0
	left join openmrs_area18_anc.user_bak c on c.ANC_user_id = p.creator
	left join openmrs_area18_anc.user_bak u on u.ANC_user_id = p.changed_by;

/* This query insert BDE person_address into main person_address  */
INSERT INTO openmrs_area18_art.person_address (person_id,  preferred,  address1,  address2,  city_village,  state_province,  postal_code,  country,  latitude,  longitude,  creator,  date_created,  voided,  voided_by,  date_voided, void_reason, county_district,  neighborhood_cell,  region,  subregion,  township_division,  uuid)
select pp.ART_patient_id, p.preferred,  p.address1,  p.address2,  p.city_village,  p.state_province, p.postal_code,  p.country,  p.latitude,  p.longitude,  c.ART_user_id,  p.date_created,  p.voided,  p.voided_by, p.date_voided, p.void_reason, p.county_district,  p.neighborhood_cell,  p.region,  p.subregion,  p.township_division, (select uuid())
from openmrs_area18_anc.person_address p 
	inner join openmrs_area18_anc.anc_last_patients_to_be_migrated pp ON pp.ANC_patient_id = p.person_id and p.voided = 0
	left join openmrs_area18_anc.user_bak c on c.ANC_user_id = p.creator;

/* This query insert BDE person_attributes into main person_attributes  */
INSERT INTO openmrs_area18_art.person_attribute (person_id, value, person_attribute_type_id, creator, date_created, changed_by, date_changed, voided, voided_by, date_voided, void_reason, uuid)
select pp.ART_patient_id, p.value, p.person_attribute_type_id, c.ART_user_id, p.date_created,  u.ART_user_id, p.date_changed, p.voided,  p.voided_by, p.date_voided, p.void_reason, (select uuid()) 
from openmrs_area18_anc.person_attribute p 
	inner join openmrs_area18_anc.anc_last_patients_to_be_migrated pp ON pp.ANC_patient_id = p.person_id and p.voided = 0
	left join openmrs_area18_anc.user_bak c on c.ANC_user_id = p.creator
	left join openmrs_area18_anc.user_bak u on u.ANC_user_id = p.changed_by;

/* This query insert BDE patient into main patient */ 
INSERT INTO openmrs_area18_art.patient (patient_id, tribe, creator, date_created, changed_by, date_changed, voided, voided_by, date_voided, void_reason)
select pp.ART_patient_id, p.tribe, c.ART_user_id, p.date_created,  u.ART_user_id, p.date_changed, p.voided,  p.voided_by, p.date_voided, p.void_reason 
from openmrs_area18_anc.patient p 
	inner join openmrs_area18_anc.anc_last_patients_to_be_migrated pp ON pp.ANC_patient_id = p.patient_id and p.voided = 0
	left join openmrs_area18_anc.user_bak c on c.ANC_user_id = p.creator
	left join openmrs_area18_anc.user_bak u on u.ANC_user_id = p.changed_by;

/* This query insert BDE patient_identifier into main patient_identifier  */
INSERT INTO openmrs_area18_art.patient_identifier (patient_id,  identifier,  identifier_type,  preferred,  location_id,  creator,  date_created,  voided,  voided_by,  date_voided,  void_reason,  uuid)
select pp.ART_patient_id, p.identifier, p.identifier_type,  p.preferred,  p.location_id,  c.ART_user_id,  p.date_created,  p.voided,  p.voided_by, p.date_voided, p.void_reason, (select uuid()) 
from openmrs_area18_anc.patient_identifier p 
	inner join openmrs_area18_anc.anc_last_patients_to_be_migrated pp ON pp.ANC_patient_id = p.patient_id and p.voided = 0
	left join openmrs_area18_anc.user_bak c on c.ANC_user_id = p.creator;

/* This query back-up main encounter  */
drop table if exists openmrs_area18_anc.encounter_bak_up;
create table  openmrs_area18_anc.encounter_bak_up as
select (select @max_encounter_id + e.encounter_id) as encounter_id, e.encounter_type, pp.ART_patient_id as patient_id, u.ART_user_id AS provider_id, e.location_id, e.form_id, e.encounter_datetime, c.ART_user_id AS creator, e.date_created, e.voided, e.voided_by, e.date_voided, e.void_reason, e.uuid, e.changed_by, e.date_changed
from openmrs_area18_anc.encounter e 
	inner join openmrs_area18_anc.anc_last_patients_to_be_migrated pp ON pp.ANC_patient_id = e.patient_id and e.voided = 0
	left join openmrs_area18_anc.user_bak c on c.ANC_user_id = e.creator
	left join openmrs_area18_anc.user_bak u on u.ANC_user_id = e.provider_id;

/* This query insert BDE encounter into main encounter  */
INSERT INTO openmrs_area18_art.encounter (encounter_id, encounter_type, patient_id, provider_id, location_id, form_id, encounter_datetime, creator, date_created, voided, voided_by, date_voided, void_reason, uuid, changed_by, date_changed, program_id)
select encounter_id, encounter_type, patient_id, provider_id, location_id, form_id, encounter_datetime, creator, date_created, voided, voided_by, date_voided, void_reason, (select uuid()), changed_by, date_changed, 12 from openmrs_area18_anc.encounter_bak_up;

/* This query back-ups patient_program table  */
drop table if exists openmrs_area18_anc.patient_program_bakup;
create table  openmrs_area18_anc.patient_program_bakup as
SELECT patient_program_id as anc_patient_program_id, (select @max_patient_program_id + patient_program_id) as patient_program_id, pp.ART_patient_id as patient_id, program_id,  date_enrolled,  date_completed,  c.ART_user_id as creator, p.date_created, u.ART_user_id as changed_by, p.date_changed,  p.voided,  p.voided_by,  p.date_voided,  p.void_reason,  p.uuid,  location_id 
FROM openmrs_area18_anc.patient_program p 
	inner join openmrs_area18_anc.anc_last_patients_to_be_migrated pp ON pp.ANC_patient_id = p.patient_id and p.voided = 0
	left join openmrs_area18_anc.user_bak c on c.ANC_user_id = p.creator
	left join openmrs_area18_anc.user_bak u on u.ANC_user_id = p.changed_by;

/* This query insert BDE patient_program into main patient_program  */
INSERT INTO openmrs_area18_art.patient_program (patient_program_id,  patient_id,  program_id,  date_enrolled,  date_completed,  creator,  date_created, changed_by,  date_changed,  voided, voided_by,  date_voided,  void_reason,  uuid,  location_id)
select patient_program_id,  patient_id,  program_id,  date_enrolled,  date_completed,  creator,  date_created, changed_by,   changed_by,  voided,  voided_by,  date_voided,  void_reason,  (SELECT UUID()), location_id from openmrs_area18_anc.patient_program_bakup;

/* This query insert BDE patient_state into main patient_state */
INSERT INTO openmrs_area18_art.patient_state (patient_program_id, state, start_date, end_date, creator, date_created, changed_by, date_changed, voided, voided_by, date_voided, void_reason, uuid)
SELECT pp.patient_program_id as patient_program_id, ps.state, ps.start_date, ps.end_date, c.ART_user_id, ps.date_created,  u.ART_user_id, ps.date_changed, ps.voided,  ps.voided_by, ps.date_voided, ps.void_reason, (SELECT UUID()) 
FROM openmrs_area18_anc.patient_state ps 
	inner join openmrs_area18_anc.patient_program_bakup pp on pp.anc_patient_program_id = ps.patient_program_id
	left join openmrs_area18_anc.user_bak c on c.ANC_user_id = ps.creator
	left join openmrs_area18_anc.user_bak u on u.ANC_user_id = ps.changed_by;

drop table if exists openmrs_area18_anc.orders_bak;

/* This query insert BDE orders into main orders */
create table openmrs_area18_anc.orders_bak as
SELECT order_id AS ANC_order_id,(SELECT @max_order_id + order_id) as ART_order_id, order_type_id, concept_id, orderer, (SELECT @max_encounter_id + encounter_id) as encounter_id, instructions,  start_date,  auto_expire_date,  discontinued,  discontinued_date, discontinued_by,  discontinued_reason, c.ART_user_id as creator, p.date_created,  p.voided,  p.voided_by,  p.date_voided,  p.void_reason, pp.ART_patient_id as patient_id,  accession_number, (SELECT @max_obs_id + obs_id) as obs_id,  uuid, discontinued_reason_non_coded 
FROM openmrs_area18_anc.orders p 
	inner join openmrs_area18_anc.anc_last_patients_to_be_migrated pp ON pp.ANC_patient_id = p.patient_id and p.voided = 0
	left join openmrs_area18_anc.user_bak c on c.ANC_user_id = p.creator;

INSERT INTO openmrs_area18_art.orders (order_id, order_type_id, concept_id, orderer,  encounter_id,  instructions,  start_date,  auto_expire_date,  discontinued,  discontinued_date, discontinued_by,  discontinued_reason, creator, date_created,  voided,  voided_by,  date_voided,  void_reason, patient_id,  accession_number, obs_id,  uuid, discontinued_reason_non_coded)
SELECT ART_order_id,  order_type_id, concept_id, orderer, encounter_id,  instructions, start_date, auto_expire_date,  discontinued,  discontinued_date, discontinued_by,  discontinued_reason,  creator,  date_created,  voided,   voided_by,  date_voided, void_reason, patient_id, accession_number, obs_id, (SELECT UUID()), discontinued_reason_non_coded FROM openmrs_area18_anc.orders_bak;

/* This query insert BDE drug_order into main drug_order */ 
INSERT INTO openmrs_area18_art.drug_order (order_id, drug_inventory_id, dose, equivalent_daily_dose, units, frequency, prn, complex, quantity)
SELECT ob.ART_order_id, dr.drug_inventory_id, dr.dose, dr.equivalent_daily_dose, dr.units, dr.frequency, dr.prn, dr.complex, dr.quantity 
FROM openmrs_area18_anc.drug_order dr 
	INNER JOIN openmrs_area18_anc.orders_bak ob on dr.order_id = ob.ANC_order_id;

/* This query insert BDE obs into main obs */
INSERT INTO openmrs_area18_art.obs (obs_id, person_id,  concept_id,  encounter_id,  order_id,  obs_datetime,  location_id,  obs_group_id,  accession_number,  value_group_id,  value_boolean,  value_coded,  value_coded_name_id,  value_drug,  value_datetime,  value_numeric,  value_modifier,  value_text,  date_started,  date_stopped,  comments,  creator,  date_created,  voided,  voided_by,  date_voided,  void_reason,  value_complex,  uuid)
SELECT (SELECT @max_obs_id + obs_id) as obs_id, pp.ART_patient_id,  concept_id,  (SELECT @max_encounter_id + encounter_id) as encounter_id,  (SELECT @max_order_id + order_id) as order_id, p.obs_datetime, p.location_id, p.obs_group_id, p.accession_number, p.value_group_id, p.value_boolean, p.value_coded, p.value_coded_name_id, p.value_drug, p.value_datetime, p.value_numeric, p.value_modifier, p.value_text, p.date_started, p.date_stopped,  p.comments, c.ART_user_id, p.date_created, p.voided, p.voided_by, p.date_voided, p.void_reason, p.value_complex,  (SELECT UUID()) 
FROM openmrs_area18_anc.obs  p 
	inner join openmrs_area18_anc.anc_last_patients_to_be_migrated pp ON pp.ANC_patient_id = p.person_id and p.voided = 0
	left join openmrs_area18_anc.user_bak c on c.ANC_user_id = p.creator;

/* Update Observation (61) encounter_type to ANC Examination (98) encounter_type */
update openmrs_area18_art.encounter set encounter_type = 98 where encounter_type = 61;

/* Update bed nets that were saved as value_text */
UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 1065, value_coded_name_id = 1102 WHERE concept_id = 2723 and value_text IN ('Given during previous ANC visit for current pregnancy', 'Given Today', 'Yes');

UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 1066, value_coded_name_id = 1103 WHERE concept_id = 2723 and value_text IN ('No', 'Not given today or during current pregnancy');

UPDATE openmrs_area18_anc.obs SET value_text = null, value_coded = 1067, value_coded_name_id = 1104 WHERE concept_id = 2723 and value_text IN ('Unknown');

/* Update Pre-eclampsia, Previous HIV Test, etc that were saved as value_text */
UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 1065, value_coded_name_id = 1102 WHERE value_text = 'Yes';

UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 1066, value_coded_name_id = 1103 WHERE value_text = 'No';

UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 1067, value_coded_name_id = 1104 WHERE value_text = 'Unknown';

UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 703, value_coded_name_id = 718 WHERE value_text = 'Positive';

UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 664, value_coded_name_id = 678 WHERE value_text = 'Negative';

UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 2475, value_coded_name_id = 5944 WHERE value_text = 'Not Done';

UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 9436, value_coded_name_id = 12655 WHERE value_text = 'Inconclusive';

/* Update Condition at Birth that were saved as value_text */
UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 2895, value_coded_name_id = 3115 WHERE concept_id = 7998 and value_text IN ('Alive');

UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 7804, value_coded_name_id = 10669 WHERE concept_id = 7998 and value_text IN ('Fresh Still Birth (FSB)');

UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 7803, value_coded_name_id = 10668 WHERE concept_id = 7998 and value_text IN ('Macerated Still Birth (MSB)');

UPDATE openmrs_area18_art.obs SET value_text = null, value_coded = 7975, value_coded_name_id = 10922 WHERE concept_id = 7998 and value_text IN ('Still Birth');

UPDATE openmrs_area18_art.encounter SET provider_id = creator WHERE provider_id = 0;

UPDATE openmrs_area18_art.encounter SET provider_id = creator WHERE provider_id IS NULL;

SET foreign_key_checks = 1;
