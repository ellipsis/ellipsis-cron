# cron.bash
#
# Main functions for ellipsis-cron
#
##############################################################################

load msg
load log

##############################################################################

cron.init() {
    CRONTAB="${CRONTAB:-$(crontab -l 2> /dev/null)}"
}

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

    # Escape name string for awk usage
    name="$(sed 's/[\/&]/\\&/g' <<< "$name")"

    # Build search string to get job
    local awk_string="f{print; f=0} /^# Ellipsis-Cron : $name\$/{f=1}"

    # Get job
    awk "$awk_string" <<< "$CRONTAB"
}

##############################################################################

cron.get_time() {
    local job="$1"
    local cln_job="$1"

    if [ "${cln_job:0:1}" = "#" ]; then
        cln_job="${cln_job:1}"
    fi

    if [ "${cln_job:0:1}" = "@" ]; then
        cut -d ' ' -f1 <<< "$job"
    else
        cut -d ' ' -f1-5 <<< "$job"
    fi
}

##############################################################################

cron.get_cmd() {
    local job="$1"
    local cln_job="$1"

    if [ "${cln_job:0:1}" = "#" ]; then
        cln_job="${cln_job:1}"
    fi

    if [ "${cln_job:0:1}" = "@" ]; then
        cut -d ' ' -f2- <<< "$job"
    else
        cut -d ' ' -f6- <<< "$job"
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
        # Escape name, time and cmd string for sed usage
        name="$(sed 's/[\/&]/\\&/g' <<< "$name")"
        time="$(sed 's/[\/&]/\\&/g' <<< "$time")"
        cmd="$(sed 's/[\/&]/\\&/g' <<< "${cmd:-$c_cmd}")"

        # Replace job line with new values
        local sed_string="/^# Ellipsis-Cron : $name\$/ { n; s/.*/$time $cmd/; }"
        CRONTAB="$(sed "$sed_string" <<< "$CRONTAB")"
    fi
}

##############################################################################

cron.add() {
    local name="$1"
    if [ -z "$name" ]; then
        msg.print "Please provide a valid job name"
        exit 1
    fi

    local time="$2"
    if [ -z "$time" ]; then
        msg.print "Please provide a valid time string"
        exit 1
    fi

    local cmd="$3"
    local job="$(cron.get_job "$name")"

    if [ -z "$job" ]; then
        if [ -z "$cmd" ]; then
            msg.print "Please provide a valid command"
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
        msg.print "Please provide a valid job name"
        exit 1
    else
        # Escape name string for sed usage
        name="$(sed 's/[\/&]/\\&/g' <<< "$name")"

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
    if [ -z "$name" -o -z "$(cron.get_job "$name")" ]; then
        msg.print "Please provide a valid job name"
        exit 1
    fi

    local job="$(cron.get_job "$name")"

    # Remove leading #'s
    if [ "${job:0:1}" = "#" ]; then
        job="${job:1}"

        local time="$(cron.get_time "$job")"
        local cmd="$(cron.get_cmd "$job")"

        cron.update_job "$name" "$time" "$cmd"

        local log_fail="Could not enable job '$name'"
        local log_ok="Enabled job '$name'"
        cron.update_crontab "$log_fail" "$log_ok"
    else
        msg.print "Job already enabled"
    fi
}

##############################################################################

cron.disable() {
    local name="$1"
    if [ -z "$name" -o -z "$(cron.get_job "$name")" ]; then
        msg.print "Please provide a valid job name"
        exit 1
    fi

    local job="$(cron.get_job "$name")"

    # Only disable if needed
    if [ "${job:0:1}" = "#" ]; then
        msg.print "Job already disabled"
    else
        local time="$(cron.get_time "$job")"
        local cmd="$(cron.get_cmd "$job")"

        cron.update_job "$name" "#$time" "$cmd"

        local log_fail="Could not disable job '$name'"
        local log_ok="Disabled job '$name'"
        cron.update_crontab "$log_fail" "$log_ok"
    fi
}

##############################################################################

cron.run() {
    local name="$1"
    if [ -z "$name" -o -z "$(cron.get_job "$name")" ]; then
        msg.print "Please provide a valid job name"
        exit 1
    fi

    local job="$(cron.get_job "$name")"
    local cmd="$(cron.get_cmd "$job")"

    # Reset ellipsis level, indentation for cron.run not needed
    (ELLIPSIS_LVL=0 eval "$cmd")
}

##############################################################################

cron.list() {

    # Print all jobs
    for name in $(cron.list_jobs); do

        local job="$(cron.get_job "$name")"

        local color1="\033[32m"
        local color2="\033[0m"

        # Remove leading #'s and mark disabled
        if [ "${job:0:1}" = "#" ]; then
            job="${job:1}"
            color1="\033[33m"
            color2="\033[0m"
        fi

        local time="$(cron.get_time "$job")"
        local cmd="$(cron.get_cmd "$job")"

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
