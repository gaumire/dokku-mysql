#!/usr/bin/env bats
load test_helper

setup() {
  dokku "$PLUGIN_COMMAND_PREFIX:create" l >&2
  dokku apps:create my_app >&2
  dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app l
}

teardown() {
  dokku "$PLUGIN_COMMAND_PREFIX:unlink" l my_app l
  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" l >&2
  rm "$DOKKU_ROOT/my_app" -rf
}

@test "($PLUGIN_COMMAND_PREFIX:promote) error when there are no arguments" {
  run dokku "$PLUGIN_COMMAND_PREFIX:promote"
  assert_contains "${lines[*]}" "Please specify a name for the service"
}

@test "($PLUGIN_COMMAND_PREFIX:promote) error when the app argument is missing" {
  run dokku "$PLUGIN_COMMAND_PREFIX:promote" l
  assert_contains "${lines[*]}" "Please specify an app to run the command on"
}

@test "($PLUGIN_COMMAND_PREFIX:promote) error when the app does not exist" {
  run dokku "$PLUGIN_COMMAND_PREFIX:promote" l not_existing_app l
  assert_contains "${lines[*]}" "App not_existing_app does not exist"
}

@test "($PLUGIN_COMMAND_PREFIX:promote) error when the service does not exist" {
  run dokku "$PLUGIN_COMMAND_PREFIX:promote" not_existing_service my_app not_existing_service
  assert_contains "${lines[*]}" "service not_existing_service does not exist"
}

@test "($PLUGIN_COMMAND_PREFIX:promote) error when the service is already promoted" {
  run dokku "$PLUGIN_COMMAND_PREFIX:promote" l my_app l
  assert_contains "${lines[*]}" "already promoted as DATABASE_URL"
}

@test "($PLUGIN_COMMAND_PREFIX:promote) changes DATABASE_URL" {
  local password="$(cat "$PLUGIN_DATA_ROOT/l/dbs/l/PASSWORD")"
  local user="$(cat "$PLUGIN_DATA_ROOT/l/dbs/l/USER")"
  dokku config:set my_app "DATABASE_URL=mysql://u:p@host:3306/db" "DOKKU_MYSQL_BLUE_URL=mysql://$user:$password@dokku-mysql-l:3306/l"
  dokku "$PLUGIN_COMMAND_PREFIX:promote" l my_app l
  url=$(dokku config:get my_app DATABASE_URL)
  assert_equal "$url" "mysql://$user:$password@dokku-mysql-l:3306/l"
}

@test "($PLUGIN_COMMAND_PREFIX:promote) creates new config url when needed" {
  local password="$(cat "$PLUGIN_DATA_ROOT/l/dbs/l/PASSWORD")"
  local user="$(cat "$PLUGIN_DATA_ROOT/l/dbs/l/USER")"
  dokku config:set my_app "DATABASE_URL=mysql://u:p@host:3306/db" "DOKKU_MYSQL_BLUE_URL=mysql://$user:$password@dokku-mysql-l:3306/l"
  dokku "$PLUGIN_COMMAND_PREFIX:promote" l my_app l
  run dokku config my_app
  assert_contains "${lines[*]}" "DOKKU_MYSQL_"
}

@test "($PLUGIN_COMMAND_PREFIX:promote) uses MYSQL_DATABASE_SCHEME variable" {
  local password="$(cat "$PLUGIN_DATA_ROOT/l/dbs/l/PASSWORD")"
  local user="$(cat "$PLUGIN_DATA_ROOT/l/dbs/l/USER")"
  dokku config:set my_app "MYSQL_DATABASE_SCHEME=mysql2" "DATABASE_URL=mysql://u:p@host:3306/db" "DOKKU_MYSQL_BLUE_URL=mysql2://$user:$password@dokku-mysql-l:3306/l"
  dokku "$PLUGIN_COMMAND_PREFIX:promote" l my_app l
  url=$(dokku config:get my_app DATABASE_URL)
  assert_contains "$url" "mysql2://$user:$password@dokku-mysql-l:3306/l"
}
