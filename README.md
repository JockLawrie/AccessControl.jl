# AccessControl

## Getting started
```
julia main.jl passwd security_level
```

- If passwd is missing then the database is not editable.
- If passwd is present but security_level is missing then the database is editable and the data is stored unencrypted.
- If passwd and security_level are present then the database is editable and the data is stored encrypted.
