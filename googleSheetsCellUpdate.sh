#!/bin/bash

howToGetAuthorizationCode() {
  CLIENT_ID=$1

  echo '👨‍💻 Authorization link: place this in a browser and use the code that is returned after you accept the scopes to update AUTHORIZATION_CODE in .env'
  SCOPES='https://www.googleapis.com/auth/spreadsheets'
  echo "https://accounts.google.com/o/oauth2/auth?client_id=$CLIENT_ID&redirect_uri=urn:ietf:wg:oauth:2.0:oob&scope=$SCOPES&response_type=code"
}

exchanceAuthorizationCodeForAccessAndRefreshTokens() {
  AUTHORIZATION_CODE=$1
  CLIENT_ID=$2
  CLIENT_SECRET=$3

  echo 'Exchange authorization code for an access token and a refresh token...'
  # 
  # Example response:
  # {
  #   "access_token": "...",
  #   "expires_in": 3599,
  #   "refresh_token": "...",
  #   "scope": "https://www.googleapis.com/auth/spreadsheets",
  #   "token_type": "Bearer"
  # }

  ACCESS_TOKEN_RESPONSE=$(curl --silent\
    --request POST \
    --data code=$AUTHORIZATION_CODE \
    --data client_id=$CLIENT_ID \
    --data client_secret=$CLIENT_SECRET \
    --data redirect_uri=urn:ietf:wg:oauth:2.0:oob \
    --data grant_type=authorization_code \
    https://accounts.google.com/o/oauth2/token)

  ACCESS_TOKEN=$(echo $ACCESS_TOKEN_RESPONSE | jq -r '.access_token')
  EXPIRES_IN=$(echo $ACCESS_TOKEN_RESPONSE | jq -r '.expires_in')
  TOKEN_TYPE=$(echo $ACCESS_TOKEN_RESPONSE | jq -r '.token_type')
  REFRESH_TOKEN=$(echo $ACCESS_TOKEN_RESPONSE | jq -r '.refresh_token')
  
  echo "ACCESS_TOKEN = $ACCESS_TOKEN"
  echo "EXPIRES_IN = $EXPIRES_IN"
  echo "TOKEN_TYPE = $TOKEN_TYPE"
  echo "REFRESH_TOKEN = $REFRESH_TOKEN"

  echo '👨‍💻 Update REFRESH_TOKEN in .env'
}

exchangeRefreshTokenForAccessToken() {
  REFRESH_TOKEN=$1
  CLIENT_ID=$2
  CLIENT_SECRET=$3

  echo 'Exchange a refresh token for a new access token...'
  # 
  # Example response:
  # {
  #   "access_token": "...",
  #   "expires_in": 3599,
  #   "scope": "https://www.googleapis.com/auth/spreadsheets",
  #   "token_type": "Bearer"
  # }

  REFRESH_TOKEN_RESPONSE=$(curl --silent\
    --request POST \
    --data client_id=$CLIENT_ID \
    --data client_secret=$CLIENT_SECRET \
    --data refresh_token=$REFRESH_TOKEN \
    --data grant_type=refresh_token \
    https://accounts.google.com/o/oauth2/token)

  ACCESS_TOKEN=$(echo $REFRESH_TOKEN_RESPONSE | jq -r '.access_token')
  EXPIRES_IN=$(echo $REFRESH_TOKEN_RESPONSE | jq -r '.expires_in')
  TOKEN_TYPE=$(echo $REFRESH_TOKEN_RESPONSE | jq -r '.token_type')

  echo "ACCESS_TOKEN = $ACCESS_TOKEN"
  echo "EXPIRES_IN = $EXPIRES_IN"
  echo "TOKEN_TYPE = $TOKEN_TYPE"
}

googleSheetsCellUpdate() {
  SPREADSHEET_ID=$1
  SHEET_NAME=$2
  RANGE=$3
  TOKEN_TYPE=$4
  ACCESS_TOKEN=$5

  echo 'Google Sheets cell update...'

  ESCAPED_SHEET_NAME=${SHEET_NAME//[ ]/\%20}
  NEW_VALUE=$RANDOM

  echo "Setting \"$SHEET_NAME!$RANGE\" to \"$NEW_VALUE\"..."

  curl --silent \
    --request PUT \
    --header "Authorization: $TOKEN_TYPE $ACCESS_TOKEN" \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --data-raw "{ \"range\": \"$SHEET_NAME!$RANGE\", \"majorDimension\": \"ROWS\", \"values\": [ [ \"$NEW_VALUE\" ] ] }" \
    "https://sheets.googleapis.com/v4/spreadsheets/$SPREADSHEET_ID/values/$ESCAPED_SHEET_NAME!$RANGE?valueInputOption=USER_ENTERED" |\
    jq '.'
}



. .env

if [ -z "$CLIENT_ID" ]; then echo "CLIENT_ID is unset"; exit 1; else echo "CLIENT_ID is set to '$CLIENT_ID'"; fi
if [ -z "$CLIENT_SECRET" ]; then echo "CLIENT_SECRET is unset"; exit 1; else echo "CLIENT_SECRET is set to '$CLIENT_SECRET'"; fi
if [ -z "$SPREADSHEET_ID" ]; then echo "SPREADSHEET_ID is unset"; exit 1; else echo "SPREADSHEET_ID is set to '$SPREADSHEET_ID'"; fi
if [ -z "$SHEET_NAME" ]; then echo "SHEET_NAME is unset"; exit 1; else echo "SHEET_NAME is set to '$SHEET_NAME'"; fi
if [ -z "$RANGE" ]; then echo "RANGE is unset"; exit 1; else echo "RANGE is set to '$RANGE'"; fi

if [ -z "$REFRESH_TOKEN" ]; then
  echo "REFRESH_TOKEN is unset"

  if [ -z "$AUTHORIZATION_CODE" ]; then
    echo "AUTHORIZATION_CODE is unset"
    howToGetAuthorizationCode $CLIENT_ID
  else
    echo "AUTHORIZATION_CODE is set to '$AUTHORIZATION_CODE'"
    exchanceAuthorizationCodeForAccessAndRefreshTokens $AUTHORIZATION_CODE $CLIENT_ID $CLIENT_SECRET
  fi
else
  echo "REFRESH_TOKEN is set to '$REFRESH_TOKEN'"
  exchangeRefreshTokenForAccessToken $REFRESH_TOKEN $CLIENT_ID $CLIENT_SECRET
  googleSheetsCellUpdate $SPREADSHEET_ID "$SHEET_NAME" $RANGE $TOKEN_TYPE $ACCESS_TOKEN
fi
