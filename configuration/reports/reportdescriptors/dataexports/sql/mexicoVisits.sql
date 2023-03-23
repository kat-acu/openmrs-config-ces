-- set @startDate = '2023-03-20';
-- set @endDate = '2023-03-24';
SET SESSION group_concat_max_len = 1000000;

set @locale =   global_property_value('default_locale', 'en');

SET @mexConsultEnc = encounter_type('aa61d509-6e76-4036-a65d-7813c0c3b752');
SET @vitEnc = encounter_type('4fb47712-34a6-40d2-8ed3-e153abbd25b7');
set @dx = concept_from_mapping('PIH','3064');	
set @med_name = concept_from_mapping('PIH','1282');
set @med_qty = concept_from_mapping('PIH','9071');
set @med_inxs = concept_from_mapping('PIH','9072');

drop temporary table if exists temp_mexico_consults;
create temporary table temp_mexico_consults
(
consult_id			int not null AUTO_INCREMENT,
patient_id          int,          
visit_id            int(11), 
first_name			varchar(255),
last_name			varchar(255),
first_last_name     varchar(511), 
age                 int,          
birthdate           date,         
gender              char(1),      
encounter_id        int,          
encounter_datetime  datetime,     
encounter_location  varchar(255), 
vitals_encounter_id int(11),
provider            varchar(255), 
temp                double,       
sbp                 int,       
dbp                 int,       
weight              double,       
height              double,       
rr                  double,       
hr                  double,       
wc                  double,       
bmi                 double,       
hdl                 double,       
ldl                 double,       
cholesterol         double,       
glucose             double,       
hiv_rapid           varchar(255), 
syphilis_rapid      varchar(255), 
hep_b               varchar(255), 
chlamydia_ag        varchar(255), 
gonorrhea_pcr       varchar(255), 
hemoglobin          double,       
blood_group         varchar(255), 
hep_c               varchar(255), 
ultrasound_type     varchar(255), 
ultrasound_notes    text,         
subjective          text,         
pe_comment          text,         
analysis            text,         
clinical_note       text,         
test_results        text,         
plan                text,         
diagnoses           varchar(1000),
rapid_tests         text,         
treatment           text,
PRIMARY KEY (consult_id)
);

-- insert all consult notes in the timeframe
insert into temp_mexico_consults (patient_id, visit_id, encounter_id, encounter_datetime,encounter_location)
select patient_id, visit_id, encounter_id, encounter_datetime, encounter_location_name(location_id) 
FROM encounter e 
where  e.voided = 0 
AND e.encounter_type in (@mexConsultEnc)
AND date(e.encounter_datetime) >= @startDate
AND date(e.encounter_datetime) <= @endDate
;

CREATE INDEX temp_mexico_consults_e on temp_mexico_consults(encounter_id);

-- create temporary table of vital signs encounters in that timeframe
drop temporary table if exists temp_vitals_encs;
create temporary table temp_vitals_encs
select encounter_id, patient_id, encounter_datetime
FROM encounter e 
where  e.voided = 0 
AND e.encounter_type in (@vitEnc)
AND date(e.encounter_datetime) >= @startDate
AND date(e.encounter_datetime) <= @endDate
;

-- update vital signs encounter_id if they occurred on same day as consult (latest on that day)
update temp_mexico_consults t
inner join encounter e on e.encounter_id =
	(select e2.encounter_id from temp_vitals_encs e2
	where e2.patient_id = t.patient_id
	and date(e2.encounter_datetime) = date(t.encounter_datetime)
	order by e2.encounter_datetime desc limit 1)
set t.vitals_encounter_id = e.encounter_id;

update temp_mexico_consults t
inner join person p on t.patient_id = p.person_id 
set t.birthdate = p.birthdate,
	t.gender = p.gender;

update temp_mexico_consults t
set first_name = person_given_name(patient_id);

update temp_mexico_consults t
set last_name = person_family_name(patient_id);

update temp_mexico_consults t
set first_last_name = concat(first_name, ' ', last_name);

update temp_mexico_consults t
set provider = provider(encounter_id);

update temp_mexico_consults t
set temp = obs_value_numeric(vitals_encounter_id, 'PIH','5088');

update temp_mexico_consults t
set hr = obs_value_numeric(vitals_encounter_id, 'PIH','5087');

update temp_mexico_consults t
set sbp = obs_value_numeric(vitals_encounter_id, 'PIH','5085');

update temp_mexico_consults t
set dbp = obs_value_numeric(vitals_encounter_id, 'PIH','5086');

update temp_mexico_consults t
set rr = obs_value_numeric(vitals_encounter_id, 'PIH','5242'); 

update temp_mexico_consults t
set weight = obs_value_numeric(vitals_encounter_id, 'PIH','5089');

update temp_mexico_consults t
set height = obs_value_numeric(vitals_encounter_id, 'PIH','5090');

update temp_mexico_consults t
set wc = obs_value_numeric(encounter_id, 'PIH','10542');

update temp_mexico_consults t
set ultrasound_type = obs_value_coded_list(encounter_id, 'PIH','14068',@locale);

update temp_mexico_consults t
set ultrasound_notes = obs_value_text(encounter_id, 'PIH','7018');

update temp_mexico_consults t
set hdl = obs_value_numeric(encounter_id, 'PIH','1007');

update temp_mexico_consults t
set ldl = obs_value_numeric(encounter_id, 'PIH','1008');

update temp_mexico_consults t
set cholesterol = obs_value_numeric(encounter_id, 'PIH','1006');

update temp_mexico_consults t
set glucose = COALESCE(obs_value_numeric(vitals_encounter_id, 'PIH','887'), obs_value_numeric(encounter_id, 'PIH','887'));

update temp_mexico_consults t
set hdl = obs_value_numeric(encounter_id, 'PIH','1007');

update temp_mexico_consults t
set hiv_rapid = obs_value_coded_list(encounter_id, 'PIH','1040',@locale);

update temp_mexico_consults t
set syphilis_rapid = obs_value_coded_list(encounter_id, 'PIH','12265',@locale);

update temp_mexico_consults t
set hep_b = obs_value_coded_list(encounter_id, 'PIH','7451',@locale);

update temp_mexico_consults t
set chlamydia_ag = obs_value_coded_list(encounter_id, 'PIH','12335',@locale);

update temp_mexico_consults t
set gonorrhea_pcr = obs_value_coded_list(encounter_id, 'PIH','12334',@locale);

update temp_mexico_consults t
set blood_group = obs_value_coded_list(encounter_id, 'PIH','300',@locale);

update temp_mexico_consults t
set hep_c = obs_value_coded_list(encounter_id, 'PIH','7452',@locale);

update temp_mexico_consults t
set hemoglobin = obs_value_numeric(encounter_id, 'PIH','21');

update temp_mexico_consults t
set subjective = obs_value_text(encounter_id, 'PIH',974);

update temp_mexico_consults t
set pe_comment  = obs_value_text(encounter_id, 'PIH',1336);

update temp_mexico_consults t
set analysis = obs_value_text(encounter_id, 'PIH',1364);

update temp_mexico_consults t
set analysis = obs_value_text(encounter_id, 'PIH',1364);

update temp_mexico_consults t
set plan = obs_value_text(encounter_id, 'PIH',10534);

drop temporary table if exists temp_dxs;
create temporary table temp_dxs
select t.encounter_id, group_concat( CONCAT(concept_name(o.value_coded,@locale),' ',retrieveICD10(o.value_coded))) "dxs"
from temp_mexico_consults t
inner join obs o on o.encounter_id = t.encounter_id and o.voided = 0 and o.concept_id = @dx
 group by t.encounter_id
;

update temp_mexico_consults t 
inner join temp_dxs td on td.encounter_id = t.encounter_id
set diagnoses = td.dxs;

drop temporary table if exists temp_meds;
create temporary table temp_meds
select t.encounter_id, 
INSERT(
	group_concat('\n', 
		CONCAT(drugName(om.value_drug),
			if(oq.value_numeric is not null, CONCAT(' cantidad: ', oq.value_numeric),''))
			) 
		,1,1,'')"meds_info"
from temp_mexico_consults t
inner join obs om on om.encounter_id = t.encounter_id and om.voided = 0 and om.concept_id = @med_name
left outer join obs oq on oq.encounter_id = t.encounter_id and oq.voided = 0 and oq.obs_group_id  = om.obs_group_id and oq.concept_id = @med_qty
 group by t.encounter_id
;

update temp_mexico_consults t 
inner join temp_meds tm on tm.encounter_id = t.encounter_id
set treatment = tm.meds_info;

update temp_mexico_consults t
set test_results = 
	CONCAT( 
		if(hdl is not null, CONCAT('HDL: ',hdl,'  '),''),
		if(ldl is not null, CONCAT('LDL: ',ldl,'  '),''),
		if(cholesterol is not null, CONCAT('Colesterol total: ',cholesterol,'  '),''),
		if(glucose is not null, CONCAT('Glucosa: ',glucose,'  '),''),
 		if(ultrasound_type is not null, CONCAT('Tipo de ultrasonido: ',ultrasound_type,'  '),''),
 		if(ultrasound_notes is not null, CONCAT('Comentario ultrasonido: ',ultrasound_notes,'  '),'')		
	);

update temp_mexico_consults t
set clinical_note = 
	CONCAT(
		'Acude ',
		first_last_name, ', ',
		gender, ' de ',
		IF(TIMESTAMPDIFF(MONTH, birthdate, encounter_datetime) < 12, TIMESTAMPDIFF(MONTH, birthdate, encounter_datetime),TIMESTAMPDIFF(YEAR, birthdate, encounter_datetime)),
		IF(TIMESTAMPDIFF(MONTH, birthdate, encounter_datetime) < 12, ' meses por ', ' años por '),
		if(provider is not null,CONCAT(provider,'. '),''),
		if(subjective is not null, CONCAT(subjective,'. '), ''),
  		if(pe_comment is not null, CONCAT(pe_comment,'. '), ''),
		if(analysis is not null, CONCAT(analysis,'. '), ''),
		if(plan is not null, CONCAT(plan,'. '), ''),
		if(temp is not null, CONCAT('TEMP: ',temp,' '),''),
		if(sbp is not null or dbp is not null, CONCAT('T/A: ',sbp,'/',dbp,' '),''),
		if(rr is not null, CONCAT('FR: ',rr,' '),''),
		if(hr is not null, CONCAT('FC: ',hr,' '),'')		
		);
		
update temp_mexico_consults t
set rapid_tests = 
INSERT (
	CONCAT(
		if(hiv_rapid is not null,CONCAT(',VIH: ',hiv_rapid),''),
		if(syphilis_rapid is not null,CONCAT(', Sífilis: ',syphilis_rapid),''),
		if(hep_b is not null,CONCAT(',Hepatitis B: ',hep_b),''),
		if(chlamydia_ag is not null,CONCAT(',Clamidia: ',chlamydia_ag),''),
		if(gonorrhea_pcr is not null,CONCAT(',Gonorrea: ',gonorrhea_pcr),''),
		if(blood_group is not null,CONCAT(',Tipo de sangre: ',blood_group),''),
		if(hep_c is not null,CONCAT(',Hepatitis C: ',hep_c),''),
		if(hemoglobin is not null,CONCAT(',Hemoglobina: ',hemoglobin),'')		
		)
	,1,1,'');
	
-- final output of all columns needed
select 
	CONCAT(LEFT(first_name,1),LEFT(last_name,1),'-',consult_id) "consult_id",
	encounter_id,
	first_last_name,
	CASE encounter_location
		when 'Honduras' then 'Casa de Salud Honduras'
		when 'Laguna del Cofre' then 'CSR Laguna del Cofre'
		when 'Capitan' then 'Unidad Médica Rural Capitán Luis A. Vidal'
		when 'Letrero' then 'CSR El Letrero'
		when 'CSR El Letrero' then 'Casa de Salud Salvador Urbina'
		when 'Soledad' then 'Casa de Salud La Soledad'		
		when 'Matazano ' then 'ESI El Matasanos'		
		when 'Plan Alta' then 'Casa de Salud Plan de la Libertad'		
		when 'Plan Baja' then 'Casa de Salud Plan de la Libertad'			
		when 'Reforma' then 'CSR Reforma'		
	END "clinic",
	birthdate,
	gender,
	TIMESTAMPDIFF(YEAR, birthdate, now()) "age",
	date(encounter_datetime) "date",
	TIME_FORMAT(encounter_datetime,'%H:%i') "time",
	temp,
	concat(sbp,'/',dbp) bp,
	weight,
	height,
	rr,
	hr,
	wc,
	ROUND(weight / ((height / 100) * (height / 100)),1) "bmi",
	test_results,
	clinical_note,
	diagnoses,
	rapid_tests,
	treatment
from temp_mexico_consults;
