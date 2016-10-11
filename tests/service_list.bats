#!/usr/bin/env bats
load test_helper

setup() {
  dokku "$PLUGIN_COMMAND_PREFIX:create" l >&2
}

teardown() {
  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" l >&2
}

@test "($PLUGIN_COMMAND_PREFIX:list) with no exposed ports, no linked apps" {
  sleep 10
  run dokku "$PLUGIN_COMMAND_PREFIX:list"
  assert_contains "${lines[*]}" "l     shrebo/mysql5.5:latest  running  -              -"
}

@test "($PLUGIN_COMMAND_PREFIX:list) with exposed ports" {
  dokku "$PLUGIN_COMMAND_PREFIX:expose" l 4242
  run dokku "$PLUGIN_COMMAND_PREFIX:list"
  assert_contains "${lines[*]}" "l     shrebo/mysql5.5:latest  running  3306->4242     -"
}

@test "($PLUGIN_COMMAND_PREFIX:list) with linked app" {
  dokku apps:create my_app
  dokku "$PLUGIN_COMMAND_PREFIX:link" l my_app l
  run dokku "$PLUGIN_COMMAND_PREFIX:list"
  assert_contains "${lines[*]}" "l     shrebo/mysql5.5:latest  running  -              my_app"
  dokku --force apps:destroy my_app
}

@test "($PLUGIN_COMMAND_PREFIX:list) when there are no services" {
  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" l >&2
  run dokku "$PLUGIN_COMMAND_PREFIX:list"
  assert_contains "${lines[*]}" "There are no MySQL services"
  dokku "$PLUGIN_COMMAND_PREFIX:create" l >&2
}
