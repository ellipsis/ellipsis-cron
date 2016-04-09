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

# Make sure local crontab isn't altered by accident
crontab() {
    :
}

##############################################################################

helper.cron.init() {
    # Custom crontab command for this test
    crontab() {
        echo "test2"
    }
    cron.init
    echo "$CRONTAB"
}

helper.cron.update_job() {
    cron.update_job "$@" && echo "$CRONTAB"
}

helper.cron.add() {
    cron.add "$@" && echo "$CRONTAB"
}

helper.cron.chtime() {
    cron.chtime "$@" && echo "$CRONTAB"
}

helper.cron.chcmd() {
    cron.chcmd "$@" && echo "$CRONTAB"
}

helper.cron.remove() {
    cron.remove "$@" && echo "$CRONTAB"
}

helper.cron.rename() {
    cron.rename "$@" && echo "$CRONTAB"
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

@test "cron.update_job updates job in crontab" {
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

@test "cron.add adds new job to crontab" {
    cron.update_crontab() {
        echo "cron.update_crontab"
    }

    CRONTAB=""
    run helper.cron.add ellipsis.test_new '@reboot' 'echo "test"'
    [ "$status" -eq 0 ]
    [ "$output" = "cron.update_crontab"$'\n'"$(cat "$TESTS_DIR/crontab/file2.cron")" ]

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run helper.cron.add ellipsis.test_new '@reboot' 'echo "test"'
    [ "$status" -eq 0 ]
    [ "$output" = "cron.update_crontab"$'\n'"$(cat "$TESTS_DIR/crontab/file3.cron")" ]
}

@test "cron.add fails if job name is missing" {
    cron.update_crontab() {
        echo "ERROR"
    }

    run cron.add
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]
}

@test "cron.add fails if time is missing" {
    cron.update_crontab() {
        echo "ERROR"
    }

    run cron.add ellipsis.test
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid time string" ]
}

@test "cron.add fails if command is missing" {
    cron.update_crontab() {
        echo "ERROR"
    }

    run cron.add ellipsis.test @reboot
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid command" ]
}

@test "cron.add fails if job already exists" {
    cron.update_crontab() {
        echo "ERROR"
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.add ellipsis.test @reboot 'echo "test"'
    [ "$status" -eq 1 ]
    [ "$output" = "Job 'ellipsis.test' already exists" ]
}

@test "cron.chtime changes time string of a job" {
    cron.update_crontab() {
        echo "cron.update_crontab"
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file2.cron")"
    run helper.cron.chtime ellipsis.test_new '@hourly'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "cron.update_crontab" ]
    [ "${lines[1]}" = "# Ellipsis-Cron : ellipsis.test_new" ]
    [ "${lines[2]}" = '@hourly echo "test"' ]
}

@test "cron.chtime only alters crontab if needed" {
    cron.update_crontab() {
        echo "ERROR"
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file2.cron")"
    run helper.cron.chtime ellipsis.test_new '@reboot'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Nothing to be done" ]
}

@test "cron.chtime fails if job name is invalid" {
    cron.update_crontab() {
        echo "ERROR"
    }

    CRONTAB=""
    run cron.chtime
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]

    CRONTAB=""
    run cron.chtime ellipsis.test
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]
}

@test "cron.chtime fails if new time is missing" {
    cron.update_crontab() {
        echo "ERROR"
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.chtime ellipsis.test
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid time string" ]
}

@test "cron.chcmd changes command of a job" {
    cron.update_crontab() {
        echo "cron.update_crontab"
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file2.cron")"
    run helper.cron.chcmd ellipsis.test_new 'echo "test2"'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "cron.update_crontab" ]
    [ "${lines[1]}" = "# Ellipsis-Cron : ellipsis.test_new" ]
    [ "${lines[2]}" = '@reboot echo "test2"' ]
}

@test "cron.chcmd only alters crontab if needed" {
    cron.update_crontab() {
        echo "ERROR"
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file2.cron")"
    run helper.cron.chcmd ellipsis.test_new 'echo "test"'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Nothing to be done" ]
}


@test "cron.chcmd fails if job name is invalid" {
    cron.update_crontab() {
        echo "ERROR"
    }

    CRONTAB=""
    run cron.chcmd
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]

    CRONTAB=""
    run cron.chcmd ellipsis.test
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]
}

@test "cron.chcmd fails if new cmd is missing" {
    cron.update_crontab() {
        echo "ERROR"
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.chcmd ellipsis.test
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid command" ]
}

@test "cron.remove removes job from crontab" {
    cron.update_crontab() {
        echo "cron.update_crontab"
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file3.cron")"
    run helper.cron.remove ellipsis.test_new
    [ "$status" -eq 0 ]
    [ "$output" = "cron.update_crontab"$'\n'"$(cat "$TESTS_DIR/crontab/file1.cron")" ]
}

@test "cron.remove fails if job name is invalid" {
    cron.update_crontab() {
        echo "ERROR"
    }

    run cron.remove
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]

    run cron.remove ellipsis.invalid
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]
}

@test "cron.remove all removes all jobs from crontab" {
    cron.update_crontab() {
        :
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run helper.cron.remove all
    [ "$status" -eq 0 ]
    [ "$output" = "$(cat "$TESTS_DIR/crontab/file1.cron.clean")" ]
}

@test "cron.rename renames a job in the crontab" {
    cron.update_crontab() {
        echo "cron.update_crontab"
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run helper.cron.rename ellipsis.test ellipsis.test_new
    [ "$status" -eq 0 ]
    [ "$output" = "cron.update_crontab"$'\n'"$(cat "$TESTS_DIR/crontab/file1.cron.rename")" ]
}

@test "cron.rename fails if job name is invalid" {
    cron.update_crontab() {
        echo "ERROR"
    }

    run cron.rename
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]

    run cron.rename ellipsis.invalid
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]
}

@test "cron.rename fails if new job name is invalid" {
    cron.update_crontab() {
        echo "ERROR"
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.rename ellipsis.test
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a new job name" ]

    run cron.rename ellipsis.test ellipsis.disabled
    [ "$status" -eq 1 ]
    [ "$output" = "Job 'ellipsis.disabled' already exists" ]
}

@test "cron.enable does nothing for already enabled job" {
    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.enable ellipsis.test
    [ "$status" -eq 0 ]
    [ "$output" = "Job already enabled" ]
}

@test "cron.enable enables disabled job" {
    cron.update_job() {
        echo "cron.update_job $@"
    }
    cron.update_crontab() {
        echo "cron.update_crontab"
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.enable ellipsis.disabled
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "cron.update_job ellipsis.disabled @reboot echo \"ellipsis.test\"" ]
    [ "${lines[1]}" = "cron.update_crontab" ]
}

@test "cron.enable fails if job name is invalid" {
    run cron.enable
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]

    run cron.enable ellipsis.invalid
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]
}

@test "cron.disable does nothing for already disabled job" {
    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.disable ellipsis.disabled
    [ "$status" -eq 0 ]
    [ "$output" = "Job already disabled" ]
}

@test "cron.disable disables enabled job" {
    cron.update_job() {
        echo "cron.update_job $@"
    }
    cron.update_crontab() {
        echo "cron.update_crontab"
    }

    CRONTAB="$(cat "$TESTS_DIR/crontab/file1.cron")"
    run cron.disable ellipsis.test
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "cron.update_job ellipsis.test #@reboot echo \"ellipsis.test\"" ]
    [ "${lines[1]}" = "cron.update_crontab" ]
}

@test "cron.disable fails if job name is invalid" {
    run cron.disable
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]

    run cron.disable ellipsis.invalid
    [ "$status" -eq 1 ]
    [ "$output" = "Please provide a valid job name" ]
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
