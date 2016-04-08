#!/usr/bin/env bats
##############################################################################

load _helper
load cron

##############################################################################

setup() {
    mkdir -p "$TESTS_DIR/tmp"
}

teardown() {
    rm -rf "$TESTS_DIR/tmp"
}

helper.cron.init() {
    # Custom crontab command for this test
    crontab() {
        echo "test2"
    }
    cron.init
    echo "$CRONTAB"
}

helper.cron.add_new() {
    cron.add_new "$@"
    echo "$CRONTAB"
}

helper.cron.update_job() {
    cron.update_job "$@"
    echo "$CRONTAB"
}

##############################################################################

@test "cron.init reads the crontab contents from '\$CRONTAB' first" {
    CRONTAB="test1"
    run helper.cron.init
    [ "$status" -eq 0 ]
    [ "$output" = "test1" ]
}

@test "cron.init reads the crontab contents using crontab command" {
    run helper.cron.init
    [ "$status" -eq 0 ]
    [ "$output" = "test2" ]
}

@test "cron.update_crontab updates the crontab file" {
    # Custom crontab command for this test
    crontab() {
        while read tmp; do
            echo "$tmp" >> "$TESTS_DIR/tmp/new.cron"
        done
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.update_crontab "test not-ok" "test ok"
    [ "$status" -eq 0 ]
    [ "$output" = "[ ok ] test ok" ]
    [ "$(cat "$TESTS_DIR/tmp/new.cron")" = "$(cat "$TESTS_DIR/crontab/file1.cron")" ]
}

@test "cron.update_crontab fails if crontab returns error" {
    # Custom crontab command for this test
    crontab() {
        return 1
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.update_crontab "test not-ok" "test ok"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "[FAIL] test not-ok" ]
    [ "${lines[1]}" = "Please check your syntax and try again!" ]
}

@test "cron.list_jobs lists cron jobs" {
    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.list_jobs
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "ellipsis.update" ]
    [ "${lines[1]}" = "ellipsis.test" ]
    [ "${lines[2]}" = "ellipsis.disabled" ]
}

@test "cron.get_job returns cron job" {
    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.get_job ellipsis.update
    [ "$status" -eq 0 ]
    [ "$output" = '@reboot $HOME/.ellipsis/bin/ellipsis update >/dev/null 2>&1' ]

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.get_job ellipsis.disabled
    [ "$status" -eq 0 ]
    [ "$output" = '#@reboot echo "ellipsis.test"' ]
}

@test "cron.get_time returns time from job" {
    run cron.get_time "@reboot echo test"
    [ "$status" -eq 0 ]
    [ "$output" = "@reboot" ]

    run cron.get_time "* 1 * */5 * echo test"
    [ "$status" -eq 0 ]
    [ "$output" = "* 1 * */5 *" ]

    run cron.get_time "#@reboot echo test"
    [ "$status" -eq 0 ]
    [ "$output" = "#@reboot" ]

    run cron.get_time "#* 1 * */5 * echo test"
    [ "$status" -eq 0 ]
    [ "$output" = "#* 1 * */5 *" ]
}

@test "cron.get_cmd returns command from job" {
    run cron.get_cmd "@reboot echo test"
    [ "$status" -eq 0 ]
    [ "$output" = "echo test" ]

    run cron.get_cmd "* 1 * */5 * echo test"
    [ "$status" -eq 0 ]
    [ "$output" = "echo test" ]

    run cron.get_cmd "#@reboot echo test"
    [ "$status" -eq 0 ]
    [ "$output" = "echo test" ]

    run cron.get_cmd "#* 1 * */5 * echo test"
    [ "$status" -eq 0 ]
    [ "$output" = "echo test" ]
}

@test "cron.add_new adds new job to crontab" {
    CRONTAB=""
    run helper.cron.add_new ellipsis.test_new '@reboot' 'echo "test"'
    [ "$status" -eq 0 ]
    [ "$output" = "$(cat "$TESTS_DIR/crontab/file2.cron")" ]

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run helper.cron.add_new ellipsis.test_new '@reboot' 'echo "test"'
    [ "$status" -eq 0 ]
    [ "$output" = "$(cat "$TESTS_DIR/crontab/file3.cron")" ]
}

@test "cron.update_job updates job in crontab" {
    CRONTAB="$(cat "$TESTS_DIR/crontab/file2.cron")"
    run helper.cron.update_job ellipsis.test_new '@reboot' 'echo "test"'
    [ "$status" -eq 0 ]
    [ "$output" = "Nothing to be done"$'\n'"$(cat "$TESTS_DIR/crontab/file2.cron")" ]

    CRONTAB="$(cat "$TESTS_DIR/crontab/file2.cron")"
    run helper.cron.update_job ellipsis.test_new '@hourly' 'echo "test"'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "# Ellipsis-Cron : ellipsis.test_new" ]
    [ "${lines[1]}" = '@hourly echo "test"' ]

    CRONTAB="$(cat "$TESTS_DIR/crontab/file2.cron")"
    run helper.cron.update_job ellipsis.test_new '@reboot' 'echo "test2"'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "# Ellipsis-Cron : ellipsis.test_new" ]
    [ "${lines[1]}" = '@reboot echo "test2"' ]
}

@test "cron.add adds or updates job in crontab" {
    skip "No test implementation"
}

@test "cron.remove removes job from crontab" {
    skip "No test implementation"
}

@test "cron.enable enables job" {
    skip "No test implementation"
}

@test "cron.disable disables job" {
    skip "No test implementation"
}

@test "cron.run runs job" {
    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.run ellipsis.test
    [ "$status" -eq 0 ]
    [ "$output" = "ellipsis.test" ]
}

@test "cron.run fails if job name is invalid" {
    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.run ellipsis.invalid
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]
}

@test "cron.list lists jobs" {
    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    ELLIPSIS_FORCE_COLOR=1
    run cron.list
    [ "$status" -eq 0 ]
    [ "$output" = "$(cat "$TESTS_DIR/crontab/file1.cron.list")" ]
}

@test "cron.edit lets you edit the crontab file" {
    crontab(){
        echo "crontab $@"
    }

    run cron.edit
    [ "$status" -eq 0 ]
    [ "$output" = "crontab -e" ]
}

@test "cron.edit fails if crontab returns error" {
    crontab(){
        return 1
    }

    run cron.edit
    [ "$status" -eq 1 ]
    [ "$output" = "[FAIL] Could not edit crontab" ]
}

##############################################################################
