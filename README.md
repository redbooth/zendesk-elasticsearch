# Zedesk-Elasticsearch

## About
At [AeroFS](http:///www.aerofs.com), our team technical support engineers helps users deploy and troubleshoot our products. We use [Zendesk](www.zendesk.com) to track communication with our customers in support tickets, and we document a lot of technical notes in that system while we investigate and troubleshoot. We think Zendesk is great for communicating, but we wanted to index the technical details in the tickets and unlock the institutional memory stored in them. As a part of our [2015 Thanksgiving Hackathon](https://www.aerofs.com/blog/how-we-run-hackathons/), we built Zendesk-Search to index and let us quickly search our support tickets.

## How does it work?
This project has two main components:

* A series of Rake tasks that poll the [Zendesk API](https://developer.zendesk.com/rest_api/docs/core/introduction) for [incremental updates](https://developer.zendesk.com/rest_api/docs/core/incremental_export) to support tickets and index ticket details in an [Elasticsearch](http://www.elasticsearch.org) instance.
* A simple Ruby on Rails web application with a search box interface for finding tickets in Elasticsearch and viewing them in a browser.

## How to Prepare
The calls to incremental updates API must be authenticated with a Zendesk Administrator's email address and API token. Generate an API token for an Administrator's user account using the Zendesk Admin interface at Admin > Channels > API. Note the user account name and token.

Deploying this project in a development environment has the following dependencies:

* Ruby 2.2.4
* [Bundler](http://bundler.io)
* [Elasticsearch](http://www.elasticsearch.org) 2.1.
* A Java Runtime Environment compatible with Elasticsearch

An overview of installing and configuring these dependencies is given below.


## How to Deploy in a Development Environment
### Install Ruby and Bundler
Install Ruby 2.2.4 using your favorite method. If you don't have one yet, check out [RVM](rvm.io), a flexible tool for installing and switching between Ruby builds.

This project relies on [Bundler](http://bundler.io) to track and install the required versions of gems. Check to see if you have bundler installed by running to see help information

    bundle -h

If Bundler is not found, install it using the instructions [here](http://bundler.io).

### Install Elasticsearch
Install Java and Elasticsearch 2.1 using one of the methods [here](https://www.elastic.co/guide/en/elasticsearch/reference/current/_installation.html). 

You should disable Elastisearch from receiving external requests by modifying `config/elasticsearch.yml` in the directory you downloaded. If present, comment out the following lines in the file with `#`s:

    network.bind_host
    network.publish_host
    
To bind to localhost, add to that same file:

    network.host: localhost

Restart Elasticsearch if it was running when you made the change.

### Download and Build the Project
1. Download the project to your desired location, and `cd` into its root directory. 
2. Install the required Ruby gems with

        bundle install

## How to Configure and Launch

### Configuration
The following table details required and optional application configuration. Export the values in the indicated environment variables to save the configuration. __Bold values are required and have no defaults. They must be set before launching the server the first time.__

| Quantity                                	| Environment Variable 	| Default Value                        	| Notes                                                                                                                                                                                                                                                              	|
|-----------------------------------------	|----------------------	|--------------------------------------	|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| Secret key                              	| `SECRET_KEY_BASE`     	| N/A                                  	| Defaults exist for test and development environments. You must generate one using `rake secret` to launch in production mode.                                                                                                                                      	|
| Zendesk Admin account user name         	| __`ZENDESK_ADMIN_USER`__   	| N/A                                  	| Required. It is the account's email address.                                                                                                                                                                                                                       	|
| Zendesk Admin account API token         	| __`ZENDESK_ADMIN_TOKEN`__  	| N/A                                  	| Required.                                                                                                                                                                                                                                                          	|
| Site name                               	| `SEARCH_SITE_NAME`     	| `Insert Your Site Name Here `          	|                                                                                                                                                                                                                                                                    	|
| The hostname of your Zendesk deployment 	| __`ZENDESK_HOST_NAME`__    	| N/A                                  	| Required. Takes the form `<something>.zendesk.com`                                                                                                                                                                                                                   	|
| Zendesk API port number                 	| `ZENDESK_HOST_PORT`    	| `443`                                	|                                                                                                                                                                                                                                                                    	|
| Elasticsearch host name                 	| `ES_HOST_NAME`         	| `localhost`                          	| Use `localhost` for Elasticsearch  hosts installed on the same machine as the Rails server.                                                                                                                                                                        	|
| Elasticsearch host port                 	| `ES_HOST_PORT`         	| `9200`                               	| 9200 is the default port for the Elasticsearch API                                                                                                                                                                                                                 	|
| Ticket start instant                    	| `ZENDESK_START_DATE`   	| `142007040` (2015-01-01T00:00:00+00:00) 	| This variable is used to specify how far back the ticket import should look for tickets. Tickets updated after this instant will be imported. The format is Unix time (seconds elapsed since 00:00:00 Coordinated Universal Time (UTC), Thursday, 1 January 1970.) 	|

### Run the Rake task to index your tickets
1. `cd` into the project's root directory.
2. Enter the following to test your connection to the Elasticsearch instance:

        rake testconnections:test_es_connection

3. Enter the following to test your Zendesk connection:

        rake testconections:test_zendesk_connection
        
4. If either test fails, check your network connectivity and environment variables.
5. If the tests succeed, enter the following and wait while your tickets are downloaded and indexed:

        rake updatees:reload_all_tickets


### Launch the server
1. `cd` into the project's root directory.
2. Type

        rails server
3. Point your browser to `localhost:3000` to navigate to the web application.

## Available Rake Tasks
The following tasks are available to manage the contents of the Elasticsearch index.

1. Run `rake testconnections:test_es_connection` to test the connection to Elasticsearch.
2. Run `rake testconnections:test_zendesk_connection` to test the connection to Zendesk.
3. Run `rake updatees:delete_tickets` to delete all tickets indexed in Elasticsearch.
4. Run `rake updatees:get_es_timestamp` to view the timestamp that will be used to determing how far back the system will query for the next batch of tickets when the `updatees:update_tickets` task runs.
5. Run `rake updatees:reload_all_tickets` to delete and reload all tickets indexed in Elasticsearch .
6. Run `updatees:set_es_timestamp[time_stamp]` to set the timestamp used to determine how far back the system will query for the next batch of tickets when the `updatees:update_tickets` task runs.
7. Run `updatees:update_tickets` to poll for and index the latest tickets.


## Notes
elastic sells a paid plugin called Shield that enables setting up SSL/TLS on Elasticsearch clusters. The project assumes that you do not have have this product, and that your cluster is not password protected. If Elasticsearch is not password protected, be sure to run it on the same machine as the Rails servers to protect users' posts.
