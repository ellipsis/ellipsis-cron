# Ellipsis-Cron [![Build Status][travis-image]][travis-url] [![Documentation status][docs-image]][docs-url] [![Latest tag][tag-image]][tag-url] [![Gitter chat][gitter-image]][gitter-url]

Ellipsis-Cron is an [Ellipsis][ellipsis] extension to manage cron jobs.

### Features
- Easy job management
- Fast job addition and removal
- Disabling and re-enabling of available jobs
- Manual job execution

### Install

**Requirements:** [Ellipsis][ellipsis]

```bash
# With ellipsis installed
$ ellipsis install ellipsis-cron

# Without ellipsis installed
$ curl -Ls ellipsis.sh | PACKAGES='ellipsis-cron' sh
```

The `.ellipsis/bin` folder should be added to your path. If it isn't you will
need to symlink `.ellipsis/bin/ellipsis-cron` to a folder that is in your path.

### Usage

#### Adding, removing and showing cron jobs
To add a job you simply call `ellipsis-cron add` followed by a `name`, `time`,
and `command`. Please take special care of escaping time and command strings!

```bash
# Add job to run 'ellipsis update' on startup
$ ellipsis-cron add ellipsis.update '@reboot' '$HOME/.ellipsis/bin/ellipsis update >/dev/null 2>&1'

# Add job to run 'ellipsis update' on each monday at 1pm
$ ellipsis-cron add ellipsis.update '13 * * * 1' '$HOME/.ellipsis/bin/ellipsis update >/dev/null 2>&1'
```

Display currently added jobs with `ellipsis-cron list`. This can optionally be
followed by a job name to display a single job.

To remove a job you call `ellipsis-cron remove <job name>`. You can remove all
jobs at once by using `all` as job name.
```bash
# Remove ellipsis.update job
$ ellipsis-cron remove ellipsis.update

# Remove all jobs
$ ellipsis-cron remove all

# The shorter 'rm' command is also supported
$ ellipsis-cron rm ellipsis.update
```

#### Change a job
Ellipsis-cron provides three functions to alter already added cron jobs.

- `rename` : Rename a job
- `chtime` : Alter the time interval of a job
- `chcmd`  : Alter the command of a job

```bash
# Rename ellipsis.update to dotfiles.update
$ ellipsis-cron rename ellipsis.update dotfiles.update

# Change ellipsis.update to run each monday at midnight
$ ellipsis-cron chtime ellipsis.update '* * * * 1'

# Change ellipsis.update command to output to a file
$ ellipsis-cron chcmd ellipsis.update '$HOME/.ellipsis/bin/ellipsis update >/tmp/ellipsis.update.log 2>&1`
```

#### Enabling or disabling a job
Instead of removing jobs when they are not needed for a certain amount of time,
you can simply disable them with `ellipsis-cron disable <job name>`. To re
enable the job you call `ellipsis-cron enable <job name>`.

```bash
# Disable ellipsis.update job
$ ellipsis-cron disable ellipsis.update

# Enable ellipsis.update job
$ ellipsis-cron enable ellipsis.update
```
#### Run a job manually
If you need to run a job manually just call `ellipsis-cron run <job name>`.
This will run the job in your current terminal. This can be very convenient for
debugging purposes. (Note, this will use the current `$PATH`, not the one used
by the cron daemon)

```bash
# Run ellipsis.update manually
$ ellipsis-cron run ellipsis.update
```

#### Manual crontab editing
Please be careful when manually editing the crontab file! Ellipsis-cron uses
special comments to keep track of jobs. However, if you don't alter comments
starting with `# Ellipsis-cron...` and lines following these comments you
should be fine!

```bash
# Manualy editing the crontab file
$ ellipsis-cron edit
```

### Docs
Please consult the [docs][docs-url] for more information.

Specific parts that could be off interest:
- [Installation][docs-install]
- [Usage][docs-usage]

### Development
Pull requests welcome! New code should follow the [existing style][style-guide]
(and ideally include [tests][bats]).

Suggest a feature or report a bug? Create an [issue][issues]!

### Author(s)
You can thank [these][contributors] people for all there hard work.

### License
Ellipsis-Cron is open-source software licensed under the [MIT license][mit-license].

[travis-image]: https://img.shields.io/travis/ellipsis/ellipsis-cron.svg
[travis-url]:   https://travis-ci.org/ellipsis/ellipsis-cron
[docs-image]:   https://readthedocs.org/projects/ellipsis-cron/badge/?version=master
[docs-url]:     http://ellipsis-cron.readthedocs.org/en/master
[tag-image]:    https://img.shields.io/github/tag/ellipsis/ellipsis-cron.svg
[tag-url]:      https://github.com/ellipsis/ellipsis-cron/tags
[gitter-image]: https://badges.gitter.im/ellipsis/ellipsis.svg
[gitter-url]:   https://gitter.im/ellipsis/ellipsis

[docs-install]: http://ellipsis-cron.readthedocs.org/en/master/install
[docs-usage]:   http://ellipsis-cron.readthedocs.org/en/master/usage

[ellipsis]:     https://github.com/ellipsis/ellipsis

[style-guide]:  https://google-styleguide.googlecode.com/svn/trunk/shell.xml
[bats]:         https://github.com/sstephenson/bats
[issues]:       http://github.com/ellipsis/ellipsis-cron/issues

[contributors]: https://github.com/ellipsis/ellipsis-cron/graphs/contributors
[mit-license]:  http://opensource.org/licenses/MIT
