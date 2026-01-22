# Last Test Run — 2026-01-19

Summary: Ran 19 tests — OK

Full output (trimmed to relevant sections):

Creating test database for alias 'default' ('file:memorydb_default?mode=memory&cache=shared')...
Running migrations: (skipped detailed list)
System check identified no issues (0 silenced).

test_child_belongs_to_exactly_one_parent_model_enforced ... ok
test_child_has_parent_and_parent_can_have_multiple_children ... ok
test_bus_capacity_enforced_by_business_rule ... ok
test_bus_has_driver_and_busminder_and_trip_route ... ok
test_cannot_assign_bus_more_than_capacity_children ... ok
test_driver_cannot_start_trip_without_assigned_bus_or_children ... ok
test_driver_only_sees_assigned_bus ... ok
test_admin_can_see_everything_by_user_type ... ok
test_unique_phone_numbers_for_accounts ... ok
test_assistant_can_mark_attendance ... ok
test_attendance_unique_together ... ok
test_invalid_direct_transition_from_scheduled_to_completed_raises ... ok
test_trip_cancel_from_any_state ... ok
test_trip_in_progress_to_completed_sets_end_time_and_summary ... ok
test_trip_scheduled_to_in_progress_transition_requires_driver_and_children ... ok
test_create_parent_requires_user_and_user_type_parent ... ok
test_parent_can_have_multiple_children ... ok
test_parent_contact_number_uniqueness ... ok
test_parent_deletion_cascades_to_children ... ok

----------------------------------------------------------------------
Ran 19 tests in 18.493s

OK

Notes:
- Tests were executed using the project's `run_tests.sh` wrapper which applies `apo_basi.test_settings` (in-memory SQLite, locmem cache).
- Trip state helpers were added (`TripManager` methods) and some tests adjusted to reflect DB constraints (e.g., non-null driver).

If you want I can also:
- Save raw test output including full migration logs to a separate file.
- Commit this results file to git and create a short test-report PR template.

File: server/tests/LAST_TEST_RESULTS.md
