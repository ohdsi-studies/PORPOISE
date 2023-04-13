DELETE FROM @target_database_schema.@target_cohort_table where cohort_definition_id = @test_cohort_id;

INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
select @test_cohort_id as cohort_definition_id, subject_id, cohort_start_date, cohort_end_date
FROM @target_database_schema.@target_cohort_table
WHERE cohort_definition_id = @target_cohort_id AND subject_id NOT IN (@train_subject_ids)
;