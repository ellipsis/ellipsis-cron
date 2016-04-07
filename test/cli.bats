#!/usr/bin/env bats
##############################################################################

load _helper
load cli

##############################################################################

@test "cli.run without command prints usage" {
    run cli.run
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Usage: ellipsis-$ELLIPSIS_XNAME_L <command>" ]
}

@test "cli.run with invalid command prints usage" {
    run cli.run invalid_command
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Usage: ellipsis-$ELLIPSIS_XNAME_L <command>" ]
}

@test "cli.run help prints usage" {
    run cli.run help
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Usage: ellipsis-$ELLIPSIS_XNAME_L <command>" ]
}

@test "cli.run --help prints usage" {
    run cli.run --help
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Usage: ellipsis-$ELLIPSIS_XNAME_L <command>" ]
}

@test "cli.run -h prints usage" {
    run cli.run -h
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Usage: ellipsis-$ELLIPSIS_XNAME_L <command>" ]
}

@test "cli.run version prints version" {
    run cli.run version
    [ "$status" -eq 0 ]
    [ $(expr "$output" : "v[0-9][0-9.]*") -ne 0 ]
}

@test "cli.run --version prints version" {
    run cli.run --version
    [ "$status" -eq 0 ]
    [ $(expr "$output" : "v[0-9][0-9.]*") -ne 0 ]
}

@test "cli.run -v prints version" {
    run cli.run -v
    [ "$status" -eq 0 ]
    [ $(expr "$output" : "v[0-9][0-9.]*") -ne 0 ]
}

@test "cli.run fails if Ellipsis version is not sufficient" {
    ELLIPSIS_VERSION="1.4.7"\
    run cli.run
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "[FAIL] Ellipsis-$ELLIPSIS_XNAME v$ELLIPSIS_XVERSION needs at least Ellipsis v$ELLIPSIS_VERSION_DEP" ]
    [ "${lines[1]}" = "Please update Ellipsis!" ]
}

@test "cli.run fails if crontab is not available" {
    # Custom cmd_exists function for this test
    utils.cmd_exists() {
        if [ "$1" = "crontab" ]; then
            return 1
        else
            return 0
        fi
    }

    run cli.run
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "[FAIL] Could not run crontab" ]
    [ "${lines[1]}" = "Please make sure crontab is installed" ]
}

@test "cli.run warns if cron daemon is not running" {
    # custom ps function for this test
    ps() {
        :
    }

    CRONTAB=""\
    run cli.run -v
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "[warn] Could not detect running cron daemon!" ]
}

##############################################################################
