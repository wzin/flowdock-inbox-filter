# Flowdock inbox filter

App for creating nice github reports from your Flowdock's team inbox

# Requirements

- ruby
- bundler
- flowdock access

# Installation

- get flowdock personal API token from
  [here](https://flowdock.com/account/tokens)
- install required gems:
```bash
bundle install
```

# Usage

```bash
ruby flowdock.rb --api-token=96a47cc1a07ac2562010538e1310befd --organization=myorganization --flow devops --user wzin
```


When in doubt:
```bash
ruby flowdock.rb --help
```


