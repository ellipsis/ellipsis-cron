# cron.bash
#
# Main functions for ellipsis-cron
#
##############################################################################

load msg
load log

##############################################################################

CRONTAB="${CRONTAB:-$(crontab -l 2> /dev/null)}"

##############################################################################

cron.update_crontab() {
    local log_fail="$1"
    local log_ok="$2"

    if ! crontab <<< "$CRONTAB"; then
        log.fail "$log_fail"
        msg.print "Please check your syntax and try again!"
        exit 1
    else
        log.ok "$log_ok"
    fi
}

##############################################################################

cron.list_jobs() {
    awk '/^# Ellipsis-Cron : / { print $NF }' <<< "$CRONTAB"
}

##############################################################################

cron.get_job() {
    local name="$1"

    # Build search string to get job
    local awk_string="f{print; f=0} /^# Ellipsis-Cron : $name\$/{f=1}"

    # Get job
    awk "$awk_string" <<< "$CRONTAB"
}

##############################################################################

cron.get_time() {
    local job="$1"

    if [ "${job:0:1}" = "@" ]; then
        cut -d ' ' -f1 <<< "$job"
    else
        cut -d ' ' -f1-5 <<< "$job"
    fi
}

##############################################################################

cron.get_cmd() {
    local job="$1"

    if [ "${job:0:1}" = "@" ]; then
        cut -d ' ' --complement -f1 <<< "$job"
    else
        cut -d ' ' --complement -f1-5 <<< "$job"
    fi
}

##############################################################################

cron.add_new() {
    local name="$1"
    local time="$2"
    local cmd="$3"

    # Add newline if crontab is not empty
    if [ -n "$CRONTAB" ]; then
        CRONTAB="$CRONTAB"$'\n'
    fi

    # Add job to crontab string
    CRONTAB="$CRONTAB""# Ellipsis-Cron : $name"$'\n'"$time $cmd"
}

##############################################################################

cron.update_job() {
    local name="$1"
    local time="$2"
    local cmd="$3"

    local job="$(cron.get_job "$name")"
    local c_time="$(cron.get_time "$job")"
    local c_cmd="$(cron.get_cmd "$job")"

    if [ "$time" == "$c_time" -a "${cmd:-$c_cmd}" == "$c_cmd" ]; then
        # Do nothing if time and command are the same
        msg.print "Nothing to be done"
        return 0
    else
        # Replace job line with new values
        local sed_string="/^# Ellipsis-Cron : $name\$/ { n; s/.*/$time ${cmd:-$c_cmd}/ }"
        CRONTAB="$(sed "$sed_string" <<< "$CRONTAB")"
    fi
}

##############################################################################

cron.add() {
    local name="$1"
    if [ -z "$name" ]; then
        log.fail "Please provide a valid job name"
        exit 1
    fi

    local time="$2"
    if [ -z "$time" ]; then
        log.fail "Please provide a valid time string"
        exit 1
    fi

    local cmd="$3"
    local job="$(cron.get_job "$name")"

    if [ -z "$job" ]; then
        if [ -z "$cmd" ]; then
            log.fail "Please provide a valid command"
            exit 1
        fi

        # Add new cron job
        cron.add_new "$name" "$time" "$cmd"

        local log_fail="Could not add job '$name'"
        local log_ok="Added job '$name'"
    else
        # Update existing job
        cron.update_job "$name" "$time" "$cmd"

        local log_fail="Could not update job '$name'"
        local log_ok="Updated job '$name'"
    fi

    cron.update_crontab "$log_fail" "$log_ok"
}

##############################################################################

cron.remove() {
    local name="$1"

    if [ "$name" = "all" ]; then
        # Delete all jobs
        for name in $(cron.list_jobs); do
            cron.remove "$name"
        done
    elif [ -z "$name" -o -z "$(cron.get_job "$name")" ]; then
        log.fail "Please provide a valid job name"
        exit 1
    else
        # Build sed string
        local sed_string="/^# Ellipsis-Cron : $name\$/ { N; d; }"
        CRONTAB="$(sed "$sed_string" <<< "$CRONTAB")"

        local log_fail="Could not remove job '$name'"
        local log_ok="Removed job '$name'"
        cron.update_crontab "$log_fail" "$log_ok"
    fi
}

##############################################################################

cron.enable() {
    local name="$1"

    # Buffer crontab content
    local crontab="$(crontab -l 2> /dev/null)"

    # Build search string to get job
    local awk_string="f{print; f=0} /^# Ellipsis-Cron : $name\$/{f=1}"

    # Get the job
    local job="$(awk "$awk_string" <<< "$crontab")"

    # Remove leading #'s
    if [ "${job:0:1}" = "#" ]; then
        job="${job:1}"
    fi

    # Extract time and command
    if [ "${job:0:1}" = "@" ]; then
        local time="$(cut -d ' ' -f1 <<< "$job")"
        local cmd="$(cut -d ' ' --complement -f1 <<< "$job")"
    else
        local time="$(cut -d ' ' -f1-5 <<< "$job")"
        local cmd="$(cut -d ' ' --complement -f1-5 <<< "$job")"
    fi

    cron.add "$name" "$time" "$cmd"
}

##############################################################################

cron.disable() {
    local name="$1"

    # Buffer crontab content
    local crontab="$(crontab -l 2> /dev/null)"

    # Build search string to get job
    local awk_string="f{print; f=0} /^# Ellipsis-Cron : $name\$/{f=1}"

    # Get the job
    local job="$(awk "$awk_string" <<< "$crontab")"

    # Remove leading #'s (if disabled already)
    if [ "${job:0:1}" = "#" ]; then
        job="${job:1}"
    fi

    # Extract time and command
    if [ "${job:0:1}" = "@" ]; then
        local time="$(cut -d ' ' -f1 <<< "$job")"
        local cmd="$(cut -d ' ' --complement -f1 <<< "$job")"
    else
        local time="$(cut -d ' ' -f1-5 <<< "$job")"
        local cmd="$(cut -d ' ' --complement -f1-5 <<< "$job")"
    fi

    cron.add "$name" "#$time" "$cmd"
}

##############################################################################

cron.run() {
    local name="$1"
    local opt="$2"

    # Buffer crontab content
    local crontab="$(crontab -l 2> /dev/null)"

    # Build search string to get job
    local awk_string="f{print; f=0} /^# Ellipsis-Cron : $name\$/{f=1}"

    # Get the job
    local job="$(awk "$awk_string" <<< "$crontab")"

    # Remove leading #'s
    if [ "${job:0:1}" = "#" ]; then
        job="${job:1}"
    fi

    # Extract time and command
    if [ "${job:0:1}" = "@" ]; then
        local time="$(cut -d ' ' -f1 <<< "$job")"
        local cmd="$(cut -d ' ' --complement -f1 <<< "$job")"
    else
        local time="$(cut -d ' ' -f1-5 <<< "$job")"
        local cmd="$(cut -d ' ' --complement -f1-5 <<< "$job")"
    fi

    # Reset ellipsis level indentation not needed
    (ELLIPSIS_LVL=0 eval "$cmd")
}

##############################################################################

cron.list() {
    # Buffer crontab content
    local crontab="$(crontab -l 2> /dev/null)"

    # Get all (Ellipsis-Cron) job names from the crontab file
    local job_names="$(awk '/^# Ellipsis-Cron : / { print $NF }' <<< "$crontab")"

    # Print all jobs
    for name in $job_names; do
        # Build search string to get job
        local awk_string="f{print; f=0} /^# Ellipsis-Cron : $name\$/{f=1}"

        # Get the job
        local job="$(awk "$awk_string" <<< "$crontab")"

        local color1="\033[32m"
        local color2="\033[0m"

        # Remove leading #'s and mark disabled
        if [ "${job:0:1}" = "#" ]; then
            job="${job:1}"
            color1="\033[33m"
            color2="\033[0m"
        fi

        # Extract time and command
        if [ "${job:0:1}" = "@" ]; then
            local time="$(cut -d ' ' -f1 <<< "$job")"
            local cmd="$(cut -d ' ' --complement -f1 <<< "$job")"
        else
            local time="$(cut -d ' ' -f1-5 <<< "$job")"
            local cmd="$(cut -d ' ' --complement -f1-5 <<< "$job")"
        fi

        msg.print "$color1$name$color2"
        msg.print "  $time"
        msg.print "  $cmd"
    done
}

##############################################################################

cron.edit() {
    if ! crontab -e; then
        log.fail "Could not edit crontab"
        exit 1
    fi
}

##############################################################################
