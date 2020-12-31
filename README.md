# Google Sheets cell update script

Bash script for Google Sheets cell update with OAuth 2.0.

## Requirements

- `curl`
- `jq`
- Google APIs OAuth 2.0 Client IDs Desktop credentials with the `https://www.googleapis.com/auth/spreadsheets` _scope_
- Google Sheets private document

## Setup

```bash
cp .env.example .env
```

then follow the instructions printed out by the main script

```bash
./googleSheetsCellUpdate.sh
```

## References

- [@LindaLawton](https://github.com/LindaLawton) original [GoogleAuthenticationCurl.sh Gist](https://gist.github.com/LindaLawton/cff75182aac5fa42930a09f58b63a309)
- Google APIs [dashboard](https://developers.google.com/oauthplayground/)
- Google Sheets API [writing sample](https://developers.google.com/sheets/api/samples/writing)
- Google Sheets API [_values update_ "Try this API" reference](https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets.values/update?apix=true) 
