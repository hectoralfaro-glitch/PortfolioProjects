-- Data Cleaning
SELECT *
FROM layoffs; # Data of wolrd layoffs. Two thousand records of layoffs donde by companies
			  # from around the world, from various industries.

-- 1. Removing duplicates if there's any
-- 2. Standardize the data
-- 3. Look at null or blank values
-- 4. Remove any unnecessary data

CREATE TABLE layoffs_staging
LIKE layoffs; # Creating an instance of the raw layoffs table to start the data cleaning.
			  # This will be our manipulated data. This way we'll always have the raw data
              # available in the layoffs table.

SELECT *
FROM layoffs_staging; # New staging table headers.

INSERT layoffs_staging
SELECT *
FROM layoffs; # Populating the new staging table with the raw data.

SELECT *,
-- Row number will group over the proposed groups (company, industry, ..., `date`) and number
-- sequencially every row that belongs to the same group (i.e. duplicates).
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`)
AS row_num
-- Use backticks on date since date is a key word
FROM layoffs_staging;
# WHERE row_num > 1; Won't work becuse row_num doesn't exists yet.

-- Any row labeled with a different flag than 1, is considered a duplicate. To filter these rows, a
-- CTE is created to perform a filter using a WHERE clause with row_num.

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`)
AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1; # Will return all of rows considered duplicates.

-- Checking to confirm the output values are, in fact, duplicates.
SELECT *
FROM layoffs_staging
WHERE company = 'terminus'; # Notice we found non-duplicate values labeled as duplicates.
					   # Partition needs to be done with every column, to avoid this error.

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) # Complete partition.
AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT *
FROM layoffs_staging
WHERE company = 'casper';

-- Deleting the duplicated rows
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) # Complete partition.
AS row_num
FROM layoffs_staging
)
DELETE # This won't work because you can not update a CTE.
FROM duplicate_cte
WHERE row_num > 1;

-- Creating a new table to perform the deletion. Right click on layoffs_staging, copy to clipboard,
-- Create statement, paste.
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL, 
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2; 

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) # Complete partition.
AS row_num
FROM layoffs_staging; # Inseting data into the new staging table with the row_num column value.

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;
;

DELETE
FROM layoffs_staging2
WHERE row_num > 1; # Deleting from our new staging table.
;

-- Done! Duplicates are gone. It would be easier to use a unique key, but this data set doesn't have one. So we created one
-- by partition over all of our columns. Similar to creating a key concatennating all of our attributes in excel.

-- 2. Standardizing Data

# First trimming white spaces.
SELECT company, TRIM(company)
FROM layoffs_staging2;

# Updating the new trimmed data.
UPDATE layoffs_staging2
SET company = TRIM(company);

# Notice there are industry labels that mean the same thing (crypto, crypto currency, cryptocurrency)
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'; # Update every LIKE crypto lable to Crypto.

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1; # Find a United States and a United States(.) country.

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) # Trailing will search for '.' and trim it.
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Changing the date text data type to date data type.
SELECT `date`
#STR_TO_DATE(`date`,'%m/%d/%Y') # STR_TO_DATE will take a date and convert it to the proper date data type
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y'); # Update the date values.

-- Changing the column data type, NEVER DO THIS IN RAW DATA. Only in your staging tables.
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging2;

-- 3. Dealing with nulls and blanks
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; # Check for NULL. Key information is missing at the same time. 
								 # These records might be useless.
							
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ''; # Looking for NULL or blank in industry column

SELECT *
FROM layoffs_staging2
WHERE company LIKE '%carvana%'; # Looking if any other rows of the same company have industry values,
							   # that we can use to populate the missing ones.
                               
-- Use a JOIN to populate the missing values.
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location # Locking our join on company-location combo. 
WHERE (t1.industry IS NULL OR t1.industry = '') # Selecting only values which are missing in t1 and
AND (t2.industry IS NOT NULL -- AND t2.industry != '' # do exist in t2.
);
 
 -- Translating our select statement into an update statement.
 UPDATE layoffs_staging2 t1
 JOIN layoffs_staging2 t2
	ON t1.company = t2.company
 SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND (t2.industry IS NOT NULL AND t2.industry != ''
);

-- Deleting rows with missing key information.
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- Dropping our row_num column. Not needed anymore.
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Done! Data is ready to start the exploratory analysis.