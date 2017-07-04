#!/usr/bin/env bats

load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'
load 'test_helper'

# Validation
# ------------------------------------------------------------------------------
@test "exits UNKNOWN if unrecognised option provided" {
  run $BASE_DIR/check_clamav_signatures --not-an-arg

  assert_failure 3
  assert_line "UNKNOWN: Unrecognised argument: --not-an-arg"
  assert_line --partial "Usage:"
}

@test "exits UNKNOWN if unable to locate the clam lib directory" {
  rm -r var/lib/clamav

  run $BASE_DIR/check_clamav_signatures --path var/lib/clamav

  assert_failure 3
  assert_output "UNKNOWN: Unable to locate ClamAV lib directory"
}

@test "exits UNKNOWN if unable to locate the daily signatures file" {
  rm var/lib/clamav/daily.cld

  run $BASE_DIR/check_clamav_signatures --path var/lib/clamav

  assert_failure 3
  assert_output "UNKNOWN: Unable to locate installed daily signatures"
}

@test "exits UNKNOWN if unable to locate the main signatures file" {
  rm var/lib/clamav/main.cvd

  run $BASE_DIR/check_clamav_signatures --path var/lib/clamav

  assert_failure 3
  assert_output "UNKNOWN: Unable to locate installed main signatures"
}

@test "exits UNKNOWN if unable to establish installed daily signatures version" {
  > var/lib/clamav/daily.cld

  run $BASE_DIR/check_clamav_signatures --path var/lib/clamav

  assert_failure 3
  assert_output "UNKNOWN: Unable to establish installed daily signatures version"
}

@test "exits UNKNOWN if unable to establish installed main signatures version" {
  > var/lib/clamav/main.cvd

  run $BASE_DIR/check_clamav_signatures --path var/lib/clamav

  assert_failure 3
  assert_output "UNKNOWN: Unable to establish installed main signatures version"
}

# Defaults
#------------------------------------------------------------------------------
@test "exits OK if signatures are up to date" {
  stub host \
    "-t txt current.cvd.clamav.net : echo 'current.cvd.clamav.net descriptive text "0.99.2:58:23538:1499326140:1:63:46137:305"'"

  run $BASE_DIR/check_clamav_signatures --path var/lib/clamav

  assert_success
  assert_output "OK: Signatures up to date; daily version: 23538, main version: 58"

  unstub host
}

@test "exits CRITICAL if daily signatures have expired" {
  cp $BASE_DIR/test/fixture/daily.expired.cld var/lib/clamav/daily.cld

  run $BASE_DIR/check_clamav_signatures --path var/lib/clamav

  assert_failure 2
  [[ "$output" == "CRITICAL: Signatures expired; daily version: 23515 ("*" behind), main version: 58 ("*" behind)" ]]
}

@test "exits CRITICAL if main signatures have expired" {
  cp $BASE_DIR/test/fixture/main.expired.cvd var/lib/clamav/main.cvd

  run $BASE_DIR/check_clamav_signatures --path var/lib/clamav

  assert_failure 2
  [[ "$output" == "CRITICAL: Signatures expired; daily version: 23538 ("*" behind), main version: 56 ("*" behind)" ]]
}

# --version
# ------------------------------------------------------------------------------
@test "--version prints the version" {
  run $BASE_DIR/check_clamav_signatures --version

  assert_success
  [[ "$output" == "check_clamav_signatures "?.?.? ]]
}

@test "-V is an alias for --version" {
  run $BASE_DIR/check_clamav_signatures -V

  assert_success
  [[ "$output" == "check_clamav_signatures "?.?.? ]]
}

# --help
# ------------------------------------------------------------------------------
@test "--help prints the usage" {
  run $BASE_DIR/check_clamav_signatures --help

  assert_success
  assert_line --partial "Usage: ./check_clamav_signatures"
}

@test "-h is an alias for --help" {
  run $BASE_DIR/check_clamav_signatures -h

  assert_success
  assert_line --partial "Usage: ./check_clamav_signatures"
}
