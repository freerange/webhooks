## Setting Trello/Harmonia environment variables

    $ cap env:set TRELLO_KEY=<your-trello-key>
    $ cap env:set TRELLO_TOKEN=<your-trello-token>
    $ cap env:set TRELLO_LIST_ID=<your-trello-list-id>
    $ cap env:set HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS=<hash-of-harmonia-people-versus-trello-ids>

*NOTE* To set the HARMONIA_PERSON_NAMES_VS_TRELLO_MEMBER_IDS hash, you'll need to use something like:

    "'{\"harmnoia-name\":\"trello-id\"}'"
