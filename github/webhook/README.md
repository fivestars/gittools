# GitHub WebHook URL Server

These scripts will enable you to quickly get a simple
HTTP server up and running so you can register your 
repo with GitHub to receive their WebHook post-receive
queries.

## Pre-requisites

* A server reachable from GitHub's WebHook ip addresses
    * See ./xinet.d/github-webhook for those values
* HTTPS access to your GitHub repository
* The following programs must be installed on the server
    * git
    * bash
    * xinetd
    * Python
    * netcat (the 'nc' command)

## Setup

* Create the 'git' user in the 'git' group
* Copy these scripts to your server
    * Recommended location: /opt/github-webhooks
* Create the workspace directory: /var/opt/github-webhooks
    * Ensure that it is writable by the 'git' user
* Copy or symlink ./xinet.d/github-webhook to /etc/xinet.d/
* Modify /etc/xinet.d/github-webhook
    * port: Port to listen on (default: 9000)
    * server_args: The scripts to run when a request arrives
    * user: The user to run server and scripts as (default: git)

## Actions (Scripts)

You can choose which scripts are run in response to a
WebHook request. They are run sequentially in the order
they appear in the server_args list.

stdout writes to the content of the HTTP response. While
GitHub discards the response, this can be helpful during
the debugging process.

Scripts will have access to the inbound request data via
stdin in addition to the REQUEST environment variable. Also
some helper functions are provided for convenience:

### Variables

* $REQUEST: The original request
* $HEAD: The HTTP headers from the request
* $BODY: The HTTP content from the request
* $JSON: The decoded contents of the payload body

Functions

* assign
    * Creates bash variables from the JSON data.
    * Provide a list of assignment statements
      where the right-side of the assignment is a
      javascript-like path to the desired value
    * Usage: assign &lt;VAR=path.to[3].json.value>...
    
* get
    * Retrieve a single value from within the JSON data
    * If no argument is provided, the entire JSON data
      will be returned
    * Usage: get [path.to[3].json.value]

## Developing/Testing

Some debugging information is logged to /var/log/syslog.

See the ./test/test-local and ./test/test-server scripts
to see how you can try your scripts out. The test-server
script assumes you have already set up your server and it
can receive requests.

Add the './actions/capture' script to your server_args
list to save the contents of the next request to
/tmp/github-webhook-request. Then you can use that request
as input to the test-local and test-server commands.

Once you have captured a request you can then pipe it to
the test-local and test-remote scripts, thus overriding
the default usage of 'sample-http-post'.