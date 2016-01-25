# Flowdock inbox filter

App for creating nice github reports from your Flowdock's team inbox

# Requirements

- ruby
- bundler
- flowdock access

NOTE: consider using rvm or rbenv (it's not a requirment)

# Installation

- install github integration on specific flow
- get Flowdock personal API token from
  [here](https://flowdock.com/account/tokens)
- get Github OAuth token (required for Zenhub only)
  https://github.com/settings/tokens
- get ZenHub API token https://dashboard.zenhub.io/#/settings
- get your Flowdock's flow and organization name
- install required gems:

```bash
bundle install
```

# Usage

```shell
ruby flowdock.rb --api-token ffa47cc1a07ac2562010538e1310befd \
                 --organization myorganization \
                 --flow devops \
                 --user wzin \
                 --number-of-messages 150
```

When in doubt:
```bash
ruby flowdock.rb --help
```

