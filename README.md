# OpenProject Translations Plugin

`openproject-translations` is an OpenProject plugin, which adds more languages to your OpenProject installation.

OpenProject uses crowdin for translations.
All translations a daily fetched from [our crowding project](https://crowdin.net/project/openproject). If you want to change translations, you are very welcome to do that via crowdin.

**Beware**:

* when translating `general_lang_name` do not translate the word 'English', but fill in the name of the language you are currently translating
* We are affected by a missing crowdin feature. Therefore we can only partly translate plural forms with crowdin. To change that you may write crowdin or [vote for the missing feature on uservoice](https://crowdin.uservoice.com/forums/31787-collaborative-translation-tool/suggestions/4772336-support-plural-forms-translation-for-yml). To work around this problem we currently use english translations where crowdin cannot give us a translation.


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
