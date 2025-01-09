# MongoDB Database Sync Tool

A simple bash script to pull/sync a MongoDB database from a remote server to your local environment.

## Overview

This tool provides a straightforward way to copy a MongoDB database from a remote server to your local machine. It's designed to be simple and secure, requiring explicit confirmation before any database operations.

## Prerequisites

- Bash shell
- MongoDB tools (`mongodump` and `mongorestore`) installed on your system
- Access to both source (remote) and destination (local) MongoDB instances

## Installation

1. Clone or download the script to your desired location
2. Make the script executable:
   ```bash
   chmod +x mongo-sync
   ```
3. Create a `config.yml` file in the same directory as the script (see Configuration section)

## Usage

Simply run the script without any arguments:

```bash
./mongo-sync
```

The script will:
1. Ask for confirmation before proceeding
2. Load configuration from `config.yml`
3. Dump the remote database to a temporary location
4. Restore the dump to your local database
5. Clean up temporary files

## Configuration

Create a `config.yml` file in the same directory as the script. Here's the structure:

```yaml
# Mongo-Sync Configurations

local:
  db: 'test'                  # Your local database name
  host:
    port: 27017              # Local MongoDB port
  access:
    username: ''             # Local MongoDB username (if required)
    password: ''             # Local MongoDB password (if required)

remote:
  db: 'test'                 # Remote database name
  host:
    url: ''    # Remote server URL or IP
    port: 27017             # Remote MongoDB port
  access:
    username: 'username'     # Remote MongoDB username
    password: 'password'     # Remote MongoDB password

```

### Configuration Details:

- **Local Settings:**
  - `db`: Name of your local database
  - `host.port`: Port number of your local MongoDB instance
  - `access.username`: Username for local MongoDB (if authentication is enabled)
  - `access.password`: Password for local MongoDB (if authentication is enabled)

- **Remote Settings:**
  - `db`: Name of the remote database to pull from
  - `host.url`: URL or IP address of the remote server
  - `host.port`: Port number of the remote MongoDB instance
  - `access.username`: Username for remote MongoDB (if authentication is enabled)
  - `access.password`: Password for remote MongoDB (if authentication is enabled)

## Safety Features

- Requires explicit confirmation before performing any operations
- Displays clear progress messages
- Includes error handling and cleanup
- Always performs cleanup of temporary files, even if an error occurs

## Important Notes

- The script will overwrite your local database with the remote data
- Always ensure you have backups before syncing databases
- Make sure your `config.yml` file has appropriate permissions as it may contain sensitive information
- The script creates temporary files in `/tmp/<database_name>/dump` which are automatically cleaned up after execution

## Troubleshooting

1. **Script can't find config.yml:**
   - Ensure `config.yml` is in the same directory as the script
   - Check file permissions

2. **Connection errors:**
   - Verify the connection details in `config.yml`
   - Ensure MongoDB is running on both local and remote servers
   - Check if authentication credentials are correct
   - Verify network connectivity to the remote server

3. **Permission errors:**
   - Ensure the script has execute permissions
   - Verify MongoDB user permissions on both servers
   - Check write permissions in the temporary directory
