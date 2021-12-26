#!/bin/bash

APPLICATION_NAME='KeepUp'
APPLICATION_ID='7lriFNc0muHJqnpBYmDJjkCdBP4ptEXEYaSiIZKR'
CLIENT_KEY='Hboaa5QGH79mvRQQfEXCUcjXnZlrXSlZk0axzQri'
MASTER_KEY='nUjdF7HXvZLT4uf3xAqoLWgwt6TY2eEBsQxaHt8s'
CLOUD_CODE_PATH='/Users/emanuel/Documents/keep_up/cloud/main.js'

brew services restart mongodb/brew/mongodb-community
parse-server --appId $APPLICATION_ID --clientKey $CLIENT_KEY --masterKey $MASTER_KEY --databaseURI mongodb://localhost/$APPLICATION_NAME --cloud $CLOUD_CODE_PATH