#!/bin/bash

# Exit status
readonly ERROR=1
readonly SUCCESS=0

# Dependencies
readonly DEPS=(
  "curl"
  "jq"
  "md5sum"
)

# Check dependencies
for i in "${DEPS[@]}"; do
  :
  if ! command -v "$i" &>/dev/null; then
    echo "Dependency \"$i\" not found, aborting..."
    exit $ERROR
  fi
done

function usage () {
  echo "
Usage: $(basename $0) [OPTIONS] JSON
  -a ACTION     Action (Default: read)
  -c FILE       Alternate config file
  -e VERSION    API version (Default: latest)
  -p            Pretty print response
  -t TYPE       Resource type (Default: estate)

  -h            This usage help text

OpenOffice API client

Takes request JSON as parameter.

Auth token and secret must be configured in config file.
Default config file location is ~/.ooapi-client.

Example config:

  secret='54321'
  token='13245'

Example commands:
  $(basename $0) -p '{"data":["Id","kaufpreis","lage"],"listlimit":10}'
  cat example.json | $(basename $0) -p -
  "
  exit ${1:-$SUCCESS}
}

# Initialise options
action='read'
configfile="${HOME}/.ooapi-client"
apiversion='latest'
prettyprint=false
resourcetype='estate'

# Parse command line options
while getopts a:c:e:j:p option; do
  case $option in
    a) action="$OPTARG" ;;
    c) configfile="$OPTARG" ;;
    e) apiversion="$OPTARG" ;;
    p) prettyprint=true;;
    t) resourcetype="$OPTARG" ;;

    h) usage ;;
    \?) usage $ERROR;;
  esac
done
shift $(($OPTIND - 1)); # take out the option flags

# Exit and show usage if no JSON input present
[[ ! "$*" ]] && usage $ERROR

# Set JSON input
if [ "$#" -ge 1 -a "$1" != "-" ]; then
  parameters="$@"
else
  parameters="$(cat)"
fi

# Verify JSON
if ! jq -e . >/dev/null 2>&1 <<<"$parameters"; then
    echo Failed to parse JSON input:
    echo
    echo "$parameters"
    echo
    exit $ERROR
fi

# Sort JSON keys alphabetically
parameterssorted="$(jq -cS <<<"$parameters")"

# Import config
if [ ! -f "$configfile" ]; then
  echo Config file \""$configfile"\" does not exist, aborting!
  exit $ERROR
else
  source $configfile
fi

# Check for config options
if [ -z "$secret" ]; then
  echo "Auth secret is not set or empty, check your config file!";
  exit $ERROR
fi
if [ -z "$token" ]; then
  echo "Auth token is not set or empty, check your config file!";
  exit $ERROR
fi

# Set request variables
actionid="urn:onoffice-de-ns:smart:2.5:smartml:action:${action}"
identifier=''
resourceid=''
timestamp="$(date +%s)"

# Generate HMAC
hmacparameters="${parameterssorted},${token},${actionid},${identifier},${resourceid},${secret},${timestamp},${resourcetype}"
hmacsum="${secret}$(echo -n "$hmacparameters" | md5sum | cut -d' ' -f1)"
hmac="$(echo -n "$hmacsum" | md5sum | cut -d' ' -f1)"

# Create request JSON
requestjson="{\"token\":\"${token}\",\"request\":{\"actions\":[{\"actionid\":\"${actionid}\",\"resourceid\":\"${resourceid}\",\"resourcetype\":\"${resourcetype}\",\"identifier\":\"${identifier}\",\"timestamp\":${timestamp},\"hmac\":\"${hmac}\",\"parameters\":${parameterssorted}}]}}"

# Send request to API
result=$(curl -s -X POST -H "Content-Type: application/json" -d "${requestjson}" https://api.onoffice.de/api/${apiversion}/api.php)

if [ "$prettyprint" = true ]; then
  echo "$result" | jq .
else
  echo "$result"
fi

exit $SUCCESS

