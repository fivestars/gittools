# GitHub WebHook URL Server

These scripts will enable you to quickly get a simple HTTP server up and running so that you can register your repo with GitHub to receive their WebHook post-receive queries.

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
    * user: The user to run server and scripts as (default: git)
    * port: Port to listen on (default: 9000)
    * server_args: The scripts to run when a request arrives

## Actions (Your Scripts)

You can choose which scripts are run in response to a WebHook request. They are run sequentially in the order they appear in the server_args list.

Scripts will have access to the inbound request data from two sources: stdin and the $REQUEST environment variable. Also some helper functions are provided for convenience:

Content written to stdout and stderr will become the content of the HTTP response. While GitHub discards the response, this can be helpful during the debugging process. Output written to stdout will be cumulative over your scripts and will be returned in the success response. Output written to stderr will be cleared before each script such that only the error content from the failed script will be sent back in the error response. 

### Variables

* $REQUEST: The full original request
* $HEAD: The HTTP headers from the request
* $BODY: The HTTP content from the request
* $JSON: The decoded contents of the payload body

Functions

* assign [VAR=path.to[3].json.value]...
    * Creates bash variables from the JSON data.
    * Provide a list of assignment statements where the right-side of the assignment is a javascript-like path to the desired value
    * Example: assign URL=repository.url PUSHER=pusher.name FIRST_COMMIT=commits[0].id
    
* get [path.to[3].json.value]
    * Retrieve a single value from within the JSON data
    * If no argument is provided, the entire JSON data will be returned
    * Example: get head_commit.message

## Developing/Testing

Some debugging information is logged to /var/log/syslog.

See the ./test/test-local and ./test/test-server scripts to see how you can try your scripts out. The test-server script assumes you have already set up your server and it can receive requests.

Add the './actions/capture' script to your server_args list to save the contents of the next request to /tmp/github-webhook-request. Then you can use that request as input to the test-local and test-server commands.

Once you have captured a request you can then pipe it to the test-local and test-remote scripts, thus overriding the default usage of 'sample-http-post'.

## FAQ/Troubleshooting

* I'm using the pre-receive and/or the post-receive actions, where do I find my repo so I can enable my hooks?
    * Using these actions will cause the repository in question to be cloned to /var/opt/github-webhook/repos/<owner>/<repository>.git/
    * Additionally, a work tree corresponding to the relevant ref will be checked out to /var/opt/github-webhook/repos/<owner>/<repository>/
    * You should place your hook scripts into /var/opt/github-webhook/repos/<owner>/<repository>.git/hooks/
* I've placed a hook script in my /var/opt/github-webhook/repos/<owner>/<repository>.git/hooks directory, but it's not being executed.
    * Check to make sure that the executable bit is set (chmod +x)
