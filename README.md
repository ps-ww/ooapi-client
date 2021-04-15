# OnOffice API BASH client

[API documentation](https://apidoc.onoffice.de/)

## Dependencies

- curl
- jq
- md5sum

## Usage

```
Usage: ooapi-client [OPTIONS] JSON
  -a ACTION     Action (Default: read)
  -c FILE       Alternate config file
  -e VERSION    API version (Default: latest)
  -p            Pretty print response
  -r            Print request
  -t TYPE       Resource type (Default: estate)

  -h            This usage help text

OnOffice API client

Takes request JSON as parameter.

Auth token and secret must be configured in config file.
Default config file location is ~/.ooapi-client.

Example config:
  secret='54321'
  token='13245'

Example commands:
  ooapi-client -p '{"data":["Id","kaufpreis","lage"],"listlimit":10}'
  cat example.json | ooapi-client -p -
```

