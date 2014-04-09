###
The MIT License (MIT)

Copyright (c) 2014 Pliable Matter LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
###

AWS = require 'aws-sdk'
commander = require 'commander'

RETRY_SECONDS = 10

commander._name = "throughput"
commander
	.version('1.0.0')
	.option('-t, --table <name>', 'Table Name')
	.option('-r, --read <capacity>', 'Read Capacity', parseInt)
	.option('-w, --write <capacity>', 'Write Capacity', parseInt)
	.option('-i, --id <id>', 'AWS Access Key ID')
	.option('-s, --secret <secret>', 'AWS Secret Access Key')
	.option('-R, --region <region>', 'AWS Region')
	.on '--help', () =>
		console.log """
			Example Call:
			./throughput -t my_dynamo_table -r 10 -w 5

			-t, and either -r or -w arguments are required. AWS access key id and 
			secret must be provided via arguments if the AWS_ACCESS_KEY_ID
			AWS_SECRET_ACCESS_KEY and AWS_DEFAULT_REGION environment variables
			have not been set.

		"""

commander.parse process.argv

if !(commander.table? && (commander.read? || commander.write?))
	return commander.help()

awsConfig =
	accessKeyId: if commander.id? then commander.id else process.env.AWS_ACCESS_KEY_ID
	secretAccessKey: if commander.secret? then commander.secret else process.env.AWS_SECRET_ACCESS_KEY
	region: if commander.region? then commander.region else process.env.AWS_DEFAULT_REGION
AWS.config.update awsConfig
db = new AWS.DynamoDB()

adjustThroughput = (tableName, readCapacity, writeCapacity) =>
	if !state?
		console.log "Retrieving table information"

		params =
			TableName: tableName
		db.describeTable params, (err, describe) =>
			if err?
				console.log "Error describing table #{err}"
				return;

			if describe.Table.TableStatus is "ACTIVE"
				params =
					TableName: tableName
					ProvisionedThroughput: {}

				readUnits = describe.Table.ProvisionedThroughput.ReadCapacityUnits
				writeUnits = describe.Table.ProvisionedThroughput.WriteCapacityUnits
				console.log "Current read capacity: #{readUnits}"
				console.log "Current write capacity #{writeUnits}"

				if !readCapacity
					readCapacity = readUnits

				if !writeCapacity
					writeCapacity = writeUnits

				if readUnits < readCapacity
					doubleReadUnits = readUnits * 2
					params.ProvisionedThroughput.ReadCapacityUnits = if (doubleReadUnits < readCapacity) then doubleReadUnits else readCapacity
					console.log "Increasing read capacity to: #{params.ProvisionedThroughput.ReadCapacityUnits}"
				else if readUnits > readCapacity
					params.ProvisionedThroughput.ReadCapacityUnits = readCapacity
					console.log "Decreasing read capacity to: #{params.ProvisionedThroughput.ReadCapacityUnits}"
				else
					params.ProvisionedThroughput.ReadCapacityUnits = describe.Table.ProvisionedThroughput.ReadCapacityUnits

				if writeUnits < writeCapacity
					doubleWriteUnits = writeUnits * 2
					params.ProvisionedThroughput.WriteCapacityUnits = if (doubleWriteUnits < writeCapacity) then doubleWriteUnits else writeCapacity
					console.log "Increasing write capacity to: #{params.ProvisionedThroughput.WriteCapacityUnits}"
				else if writeUnits > writeCapacity
					params.ProvisionedThroughput.WriteCapacityUnits = writeCapacity
					console.log "Decreasing write capacity to: #{params.ProvisionedThroughput.WriteCapacityUnits}"
				else
					params.ProvisionedThroughput.WriteCapacityUnits = describe.Table.ProvisionedThroughput.WriteCapacityUnits

				lastReadUnits = describe.Table.ProvisionedThroughput.ReadCapacityUnits
				thisReadUnits = params.ProvisionedThroughput.ReadCapacityUnits
				lastWriteUnits = describe.Table.ProvisionedThroughput.WriteCapacityUnits
				thisWriteUnits = params.ProvisionedThroughput.WriteCapacityUnits

				if (thisReadUnits != lastReadUnits) or (thisWriteUnits != lastWriteUnits)
					db.updateTable params, (err, update) =>
						if err?
							console.log "Error updating table #{err}"
							return
						else
							return adjustThroughput(tableName, readCapacity, writeCapacity)
				else
					console.log "Update complete"
			else
				console.log "Table is not in ACTIVE state. Retrying in #{RETRY_SECONDS} seconds"
				delay = (f) => setTimeout f, (RETRY_SECONDS * 1000)
				return delay => adjustThroughput tableName, readCapacity, writeCapacity

adjustThroughput commander.table, commander.read, commander.write