SET @sql := (
  SELECT IF(
    EXISTS (
      SELECT 1
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = 'devdb'
        AND TABLE_NAME = 'users'
        AND COLUMN_NAME = 'email'
    ),
    'SELECT "Column email already exists";',
    'ALTER TABLE devdb.users ADD COLUMN email VARCHAR(255);'
  )
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;