# Generating/storing the tokens you need to use this app

## Getting the ID of the Trello board we're interested in

    $ open https://trello.com
    # Navigate to the board you want to backup and copy the board ID from the URL
    # The structure of the URL should be trello.com/b/<board-ID>/<board-name>

    # Temporarily store the Trello board ID in an environment variable
    $ export TRELLO_BOARD_ID=`pbpaste`

## Getting the Trello API Key

Ensure you're logged in to Trello as the GFR Admin user.

    $ open "https://trello.com/1/appKey/generate"
    # Copy the Key (under Developer API Keys) to the clipboard

    # Temporarily store the Trello API key in an environment variable
    $ export TRELLO_KEY=`pbpaste`

    # Store the Trello API key in .env
    $ echo "TRELLO_KEY=$TRELLO_KEY" >> .env

## Getting a token to allow this app to read/write our Trello board

Ensure you're logged in to Trello as the GFR Admin user. It's safe to run this multiple times as you'll get the same token each time.

    $ open "https://trello.com/1/authorize?key=$TRELLO_KEY&name=gfr-trello-harmonia-webhooks&expiration=never&response_type=token&scope=read,write"
    # Allow the gfr-trello-harmonia-webhooks app to read/write our Trello account

    # Copy the token from the resulting page

    # Temporarily store the Trello token in an environment variable
    $ export TRELLO_TOKEN=`pbpaste`

    # Store the Trello token in .env
    $ echo "TRELLO_TOKEN=$TRELLO_TOKEN" >> .env

## Getting the ID of the Trello list we'll create cards in

    # Display the lists for the board we're interested in
    $ curl "https://api.trello.com/1/boards/$TRELLO_BOARD_ID/lists?card_fields=name&key=$TRELLO_KEY&token=$TRELLO_TOKEN"

    # Copy the ID of the list that you want to create cards in

    # Temporarily copy the Trello list ID to an environment variable
    $ export TRELLO_LIST_ID=`pbpaste`

    # Store the Trello list ID in .env
    $ echo "TRELLO_LIST_ID=$TRELLO_LIST_ID" >> .env

## Getting the IDs of the Trello members that we'll associate with Harmonia users

    # Display the Trello members for the board we're interested in
    $ curl "https://api.trello.com/1/boards/$TRELLO_BOARD_ID/members?key=$TRELLO_KEY&token=$TRELLO_TOKEN"

    # Use Ruby to create a JSON hash of the Trello member IDs versus their Harmonia names
    # Get the Harmonia people names from https://harmonia.io/teams/<your-team-id>
    # Get the corresponding Trello member ID from the output of the previous curl command
    $ ruby -rjson -e "puts({'harmonia-person-name' => 'trello-member-id'}.to_json)" | pbcopy

    # Temporarily copy the members hash to an environment variable
    $ export HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS=`pbpaste`

    # Store the members hash in .env
    $ echo "HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS='$HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS'" >> .env

# Deployment

## Using recap to deploy

    $ cap bootstrap
    $ cap deploy:setup
    $ cap deploy

## Set the webhooks user's shell to bash

    $ # So that Passenger can pick up environment vars from .profile
    root$ chsh -s /bin/bash webhooks

## Setting the Trello/Harmonia environment variables

    $ cap env:set TRELLO_KEY=`grep TRELLO_KEY .env | cut -d"=" -f2`
    $ cap env:set TRELLO_TOKEN=`grep TRELLO_TOKEN .env | cut -d"=" -f2`
    $ cap env:set TRELLO_LIST_ID=`grep TRELLO_LIST_ID .env | cut -d"=" -f2`
    $ cap env:set HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS="`grep HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS .env | cut -d"=" -f2`"
    $ can env:set AUTHENTICATION_TOKEN=abc123

## Copy and enable the Apache config file

    $ cap apache:enable_config

## Testing the server

Assuming you have something like the harmonia-assignment.example.json in this project.

    $ curl -XPOST -d@harmonia-assignment.example.json "http://webhooks.gofreerange.com/harmonia/assignments?token=abc123"

You'll see a response containing "OK" if everything is hooked up correctly.
