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

##############################################################################

@test "cron.init reads the crontab contents from '\$CRONTAB' first" {
    # Custom crontab command for this test
    crontab() {
        echo "test2"
    }

    CRONTAB="test1"
    cron.init
    [ "$?" -eq 0 ]
    [ "$CRONTAB" = "test1" ]
}

@test "cron.init reads the crontab contents using crontab command" {
    # Custom crontab command for this test
    crontab() {
        echo "test2"
    }

    cron.init
    [ "$?" -eq 0 ]
    [ "$CRONTAB" = "test2" ]
}

@test "cron.update_crontab updates the crontab file" {
    # Custom crontab command for this test
    crontab() {
        while read tmp; do
            echo "$tmp" >> "$TESTS_DIR/tmp/new.cron"
        done
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"\
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

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"\
    run cron.update_crontab "test not-ok" "test ok"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "[FAIL] test not-ok" ]
    [ "${lines[1]}" = "Please check your syntax and try again!" ]
}

@test "cron.list_jobs lists cron jobs" {
    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"\
    run cron.list_jobs
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "ellipsis.update" ]
    [ "${lines[1]}" = "ellipsis.test" ]
    [ "${lines[2]}" = "ellipsis.disabled" ]
}

@test "cron.get_job returns cron job" {
    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"\
    run cron.get_job ellipsis.update
    [ "$status" -eq 0 ]
    [ "$output" = '@reboot $HOME/.ellipsis/bin/ellipsis update >/dev/null 2>&1' ]

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"\
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

@test "cron.update_job updates job in crontab" {
    skip "No test implementation"
}

@test "cron.add adds job to crontab" {
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
    skip "No test implementation"
}

@test "cron.list lists jobs" {
    skip "No test implementation"
}

@test "cron.edit lets you edit the crontab file" {
    skip "No test implementation"
}

##############################################################################
