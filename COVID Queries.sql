SELECT * FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 3,4

--SELECT * FROM PortfolioProject.dbo.CovidVaccinations
--ORDER BY 3,4

-- Select the data that we are going to be using

SELECT location,
	   date,
	   total_cases,
	   new_cases,
	   total_deaths,
	   population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
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


-- Looking at the Total Cases vs Population
-- Shows what percentage of the population has contracted COVID-19

SELECT location,
	   date,
	   population,
	   total_cases,
	   (total_cases/population)*100 AS PopulationPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2


-- Looking at the countries with the highest infection rate compared to the population.

SELECT location,
	   population,
	   MAX(total_cases) AS HighestInfectionCount,
	   MAX((total_cases/population))*100 AS PopulationPercentage
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location,
		 population
ORDER BY PopulationPercentage DESC


-- Showing Countries with highest Death Count per Population

SELECT location,
	   MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,
		 population
ORDER BY TotalDeathCount DESC

-- Initially it is going to read the total_deaths as NVARCHAR and order it weird. 
-- So you need to convert (or cast) it to an integer to be sorted correctly.
-- Also, we had to add the continent not null piece because otherwise it will include in our 
-- data duplicates like Africa and World which are not countries but rather totals.



-- Now let's instead break it down by continent.

SELECT location,
	   MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Global Numbers by Date 

SELECT date,
	   SUM(new_cases) AS TotalCases,
	   SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
	   (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Global Numbers Total

SELECT SUM(new_cases) AS TotalCases,
	   SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
	   (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



-- Looking at total population vs Vaccination

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


-- Take the above and turn it into a CTE (common table expression): allows it to be referenced later.


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
--ORDER BY 2,3 -- you cannot have an order by
)

SELECT *,
	   (RollingPeopleVaccinated/Population)*100 AS PercentOfPopulationVaccinated
FROM PopVsVac
WHERE Location = 'United States'


-- Example of usinga  Temp Table instead


-- DROP Table if exists #PercentPopulationVaccinated THIS DOESN"T WORK IN THIS VERSION OF SQL SERVER
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
--ORDER BY 2,3 -- you cannot have an order by

SELECT *,
	   (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated




