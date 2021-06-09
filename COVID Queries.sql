-- 1) Initial look at dataset

SELECT * FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 3,4

--SELECT * FROM PortfolioProject.dbo.CovidVaccinations
--ORDER BY 3,4

----------------------------------------------------------------------------------------------------------------------------

-- 2) Select only the data that will be used

SELECT location,
	   date,
	   total_cases,
	   new_cases,
	   total_deaths,
	   population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2

----------------------------------------------------------------------------------------------------------------------------

-- 3) Total Cases vs Total Deaths

-- Shows the likelihood of dying if you contract COVID-19 in your country.
-- In this case, it is set to specify the United States.


SELECT location,
	   date,
	   total_cases,
	   total_deaths,
	   (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

----------------------------------------------------------------------------------------------------------------------------

-- 4) Total Cases vs Population

-- Shows what percentage of the population has contracted COVID-19
-- In this case, it is set to specify the United States.

SELECT location,
	   date,
	   population,
	   total_cases,
	   (total_cases/population)*100 AS PopulationPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

----------------------------------------------------------------------------------------------------------------------------

-- 5) Countries with the Highest Infection Rate compared to the Population.

SELECT location,
	   population,
	   MAX(total_cases) AS HighestInfectionCount,
	   MAX((total_cases/population))*100 AS PopulationPercentage
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location,
	 population
ORDER BY PopulationPercentage DESC

----------------------------------------------------------------------------------------------------------------------------

-- 6) Countries with Highest Death Count per Population

SELECT location,
	   MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,
	 population
ORDER BY TotalDeathCount DESC

-- total_deaths is NVARCHAR so it must be cast as an integer to aggregate it.
-- The location field includes both countries and continents so the where continent is not null line will 
-- ensure that only countries are shown and not continent summaries or duplicate data.

----------------------------------------------------------------------------------------------------------------------------

-- 7) Continents with Highest Death Count per Population

SELECT location,
	   MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

----------------------------------------------------------------------------------------------------------------------------

-- 8) Global Numbers by Date 

SELECT date,
	   SUM(new_cases) AS TotalCases,
	   SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
	   (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

----------------------------------------------------------------------------------------------------------------------------

-- 9) Global Numbers Total

SELECT SUM(new_cases) AS TotalCases,
	   SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
	   (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

----------------------------------------------------------------------------------------------------------------------------

-- 10) Total Population vs Vaccination

SELECT DEA.continent,
	   DEA.location,
	   DEA.date,
	   DEA.population,
	   VAC.new_vaccinations,
	   SUM(CAST(VAC.new_vaccinations AS INT)) 
			OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths AS DEA
JOIN PortfolioProject.dbo.CovidVaccinations AS VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
ORDER BY 2,3

----------------------------------------------------------------------------------------------------------------------------

-- 11) Total Population vs Vaccination CTE (common table expression): allows it to be referenced later.


WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT DEA.continent,
	   DEA.location,
	   DEA.date,
	   DEA.population,
	   VAC.new_vaccinations,
	   SUM(CAST(VAC.new_vaccinations AS INT)) 
			OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths AS DEA
JOIN PortfolioProject.dbo.CovidVaccinations AS VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
)

SELECT *,
	   (RollingPeopleVaccinated/Population)*100 AS PercentOfPopulationVaccinated
FROM PopVsVac
WHERE Location = 'United States'

----------------------------------------------------------------------------------------------------------------------------

-- 12) Total Population vs Vaccination Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT DEA.continent,
	   DEA.location,
	   DEA.date,
	   DEA.population,
	   VAC.new_vaccinations,
	   SUM(CAST(VAC.new_vaccinations AS INT)) 
			OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths AS DEA
JOIN PortfolioProject.dbo.CovidVaccinations AS VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL


SELECT *,
	   (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated




