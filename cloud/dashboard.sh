#!/bin/bash

APPLICATION_NAME='KeepUp'
APPLICATION_ID='7lriFNc0muHJqnpBYmDJjkCdBP4ptEXEYaSiIZKR'
MASTER_KEY='nUjdF7HXvZLT4uf3xAqoLWgwt6TY2eEBsQxaHt8s'

parse-dashboard --dev --appId $APPLICATION_ID --masterKey $MASTER_KEY --serverURL http://localhost:1337/parse --appName $APPLICATION_NAME