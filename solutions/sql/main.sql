SELECT city || chr(9)
    || CAST(MIN(CAST(REPLACE(temp, '.', '') AS BIGINT)) AS VARCHAR) || chr(9)
    || CAST(MAX(CAST(REPLACE(temp, '.', '') AS BIGINT)) AS VARCHAR) || chr(9)
    || CAST(SUM(CAST(REPLACE(temp, '.', '') AS BIGINT)) AS VARCHAR) || chr(9)
    || CAST(COUNT(*) AS VARCHAR)
FROM read_csv('../../data/measurements.txt',
    delim=';',
    header=false,
    columns={'city': 'VARCHAR', 'temp': 'VARCHAR'})
GROUP BY city
ORDER BY city;