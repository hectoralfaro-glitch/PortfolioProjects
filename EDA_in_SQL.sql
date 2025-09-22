-- Exploratory Data Analysis

SELECT *
FROM layoffs_staging2; 

-- Max num of layoffs
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Which companies went totally out of business?
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
# ORDER BY total_laid_off DESC;
ORDER BY funds_raised_millions DESC; # Which companies had the most fund raising?

-- The total layoffs each company (3 years). 
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Exploring the date range of our data.
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Which industry had the major layoffs?
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Which country had the major layoffs?
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Looking at layoffs as a function of time
# SELECT `date`, SUM(total_laid_off)
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`) # Grouping by YEAR.
ORDER BY 1 DESC;

-- Which stage of company had the major layoffs?
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- We don't have data on the total company before layoffs. Then looking at percentage of 
-- layoffs is not relevant.
SELECT company, AVG(percentage_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Looking at the rolling sum of layoffs.
# SUM of layoffs grouped by year-month.
SELECT SUBSTRING(`date`,1,7) AS `month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC;

-- Rolling sum of layoffs.
WITH rolling_total_CTE AS
(
SELECT SUBSTRING(`date`,1,7) AS `month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC
)
SELECT `month`, total_off,
SUM(total_off) OVER(ORDER BY `month`) AS rolling_total # AGGf + Window Function + ORDER BY = rolling sum
FROM rolling_total_CTE;

-- Sum as a function of company + year
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- Ranking each company based on their total layoffs.
WITH Company_Year(company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), company_year_rank AS
(SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM Company_Year
WHERE years IS NOT NULL)
SELECT *
FROM company_year_rank
WHERE ranking <= 5
-- ORDER BY ranking ASC
;






