
DynamoDB provisioned throughput can only be updated by 100% at a time, which can make it time consuming to increase it from a small value to large value using the management console.

This script aims to make that quicker and easier by stepping the value up or down until it reaches the desired level.

***WARNING: Setting your provisioned throughput to unexpectedly high levels and cost you a lot of money. This script should not be run unattended, and you should verify your throughput levels in the DynamoDB console after running. Use at your own risk.***

Also note that this has only been tested on Mac OS X. If you have to make any changes to get it working on Linux, Windows, etc., please submit a pull request.

## Setup
node.js is required. If you don't already have it, follow the instructions at http://nodejs.org/

Once node.js is installed, `cd` to the dynamo-modify-throughput directory and run `npm install`

Your AWS credentials and default region will need to be provided via environment variables or command line arguments. The environment variables are:
* AWS\_ACCESS\_KEY\_ID
* AWS\_SECRET\_ACCESS\_KEY
* AWS\_SECRET\_ACCESS\_KEY

## Usage
Usage: throughput [options]

  Options:

    -h, --help              output usage information
    -V, --version           output the version number
    -t, --table <name>      Table Name
    -r, --read <capacity>   Read Capacity
    -w, --write <capacity>  Write Capacity
    -i, --id <id>           AWS Access Key ID
    -s, --secret <secret>   AWS Secret Access Key
    -R, --region <region>   AWS Region

Example Call:
`./throughput -t my_dynamo_table -r 10 -w 5`

-t, -r and -w arguments are required. AWS access key id and 
secret must be provided via arguments if the AWS\_ACCESS\_KEY\_ID
AWS\_SECRET\_ACCESS\_KEY and AWS\_DEFAULT\_REGION environment variables
have not been set.

## Sample Calls

* Update Read Throughput:
 * `./throughput -t your_table_name -r 120`
* Update Write Throughput:
 * `./throughput -t your_table_name -w 10`
* Update Read and Write Throughput:
 * `./throughput -t your_table_name -r 120 -w 10`
* Show Help:
 * `./throughput -h`

