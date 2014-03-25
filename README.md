# OpenProject Translations Plugin

**Warning:** This plugin is work in progress and does not work as intended yet.

`openproject-translations` is an OpenProject plugin, which adds more languages to your OpenProject installation.

All translations a daily fetched from [our crowding project](https://crowdin.net/project/openproject). If you want to change translations, you are very welcome to do that via crowdin.



## Requirements

* OpenProject version **3.0.0 or higher** ( or a current installation from the `dev` branch)

## Installation

Edit the `Gemfile.plugins` file in your openproject-installation directory to contain the following lines:

<pre>
gem "openproject-translations", :git => 'https://github.com/finnlabs/openproject-translations.git'
</pre>

Then update your bundle with:

<pre>
bundle install
</pre>

and restart the OpenProject server.

## Get in Contact

OpenProject is supported by its community members, both companies as well as individuals. There are different possibilities of getting help:
* OpenProject [support page](https://www.openproject.org/projects/openproject/wiki/Support)
* E-Mail Support - info@openproject.org

## Start Collaborating

If you want to contribute translations, please visit [our crowin project](https://crowdin.net/project/openproject).

This plugin contains some other things than translation files -- if you want to change those, join the OpenProject community and start collaborating.
Details will can be found on the OpenProject Community [contribution page](https://www.openproject.org/projects/openproject/wiki/Contribution).

In case you find a bug or need a feature, please report at https://www.openproject.org/projects/translations/issues

## License

Copyright (C) 2014 the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md for details.
