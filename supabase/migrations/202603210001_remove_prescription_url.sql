-- Remove deprecated doctor prescription image column from medicines.
alter table if exists medicines
  drop column if exists prescription_url;
