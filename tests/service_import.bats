#!/usr/bin/env bats
load test_helper

setup() {
  export ECHO_DOCKER_COMMAND="false"
  dokku "$PLUGIN_COMMAND_PREFIX:create" l >&2
  echo "data" > "$PLUGIN_DATA_ROOT/fake.sql"
}

teardown() {
  export ECHO_DOCKER_COMMAND="false"
  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" l >&2
  rm -f "$PLUGIN_DATA_ROOT/fake.sql"
}

@test "($PLUGIN_COMMAND_PREFIX:import) error when there are no arguments" {
  run dokku "$PLUGIN_COMMAND_PREFIX:import"
  assert_contains "${lines[*]}" "Please specify a name for the service"
}

@test "($PLUGIN_COMMAND_PREFIX:export) error import without database name" {
  run dokku "$PLUGIN_COMMAND_PREFIX:export" not_existing_service
  assert_contains "${lines[*]}" "Please specify a database name"
}

@test "($PLUGIN_COMMAND_PREFIX:import) error when service does not exist" {
  run dokku "$PLUGIN_COMMAND_PREFIX:import" not_existing_service not_existing_database_name
  assert_contains "${lines[*]}" "service not_existing_service does not exist"
}

@test "($PLUGIN_COMMAND_PREFIX:import) error when data is not provided" {
  run dokku "$PLUGIN_COMMAND_PREFIX:import" l l
  assert_contains "${lines[*]}" "No data provided on stdin"
}

@test "($PLUGIN_COMMAND_PREFIX:import) success" {
  export ECHO_DOCKER_COMMAND="true"
  run dokku "$PLUGIN_COMMAND_PREFIX:import" l l < "$PLUGIN_DATA_ROOT/fake.sql"
  password="$(cat "$PLUGIN_DATA_ROOT/l/dbs/l/PASSWORD")"
  user="$(cat "$PLUGIN_DATA_ROOT/l/dbs/l/USER")"
  assert_output "docker exec -i dokku.mysql.l mysql --user=$user --password=$password l"
}

