# `(import (letloop lsm))`

SQLite3 extension LSM1.

## `(lsm-begin db level)`

Start a transaction, or a nested transaction.

## `(lsm-close db)`

Close database.

## `(lsm-commit db level)`

Commit current transaction up-to `LEVEL`.

## `(lsm-config db config value)`

Configure `db` with `CONFIG`, and `VALUE`...

## `(lsm-cursor-close cursor)`

Close cursor `CURSOR`.

## `(lsm-cursor-first cursor)`

Move the cursor to the first position, the start of the key space.

## `(lsm-cursor-key cursor)`

Return the key associated with the current position of `CURSOR`.

## `(lsm-cursor-last cursor)`

Move the cursor to the last position, the end of the key space.

## `(lsm-cursor-next cursor)`

Move `CURSOR` to the next position.

## `(lsm-cursor-open db)`

Open a cursor.

## `(lsm-cursor-prev cursor)`

Move `CURSOR` to the previous position.

## `(lsm-cursor-seek cursor key strategy)`

Seek `KEY` using one of the following strategy:

- 'less-than-or-equal-fast
- 'less-than-or-equal
- 'equal
- 'greater-than-or-equal

## `(lsm-cursor-valid? cursor)`

Return `#true` if `CURSOR` is at a valid position.

## `(lsm-cursor-value cursor)`

Return the value associated with the current position of `CURSOR`.

## `(lsm-delete db key)`

If any, remove `KEY` and its value.

## `(lsm-insert db key value)`

Insert `KEY` with `VALUE`, or update the value associated with `KEY`.

## `(lsm-new)`

Return a handle over a database. See `lsm-config`, and `lsm-open`.

## `(lsm-open db filename)`

Against `DB`, open `FILENAME`.

## `(lsm-rollback db level)`

Rollback current transaction up-to `LEVEL`.
