/*
Covid 19 Data exploration


*/

SELECT *
FROM `main-reducer-337922.covid_data.covid_deaths`
WHERE continent is not null 
ORDER BY 1,2

## Select Data that we are going to be starting with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `main-reducer-337922.covid_data.covid_deaths`
WHERE continent is not null 
order by 1,2

-- total death percentage
SELECT SUM(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as DeathPercentage 
FROM `main-reducer-337922.covid_data.covid_deaths`
WHERE continent is not null
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in the United States in 2021

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From `main-reducer-337922.covid_data.covid_deaths`
Where location like '%States%' and (date BETWEEN '2021-01-01' AND '2021-12-31')
and continent is not null 
order by 1,2



-- Total Cases vs Population
-- Shows what percentage of population have already been infected with Covid 

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From `main-reducer-337922.covid_data.covid_deaths`
WHERE continent is not null
order by 1,2


--3.  Countries with Highest Infection Rate compared to Population

Select location, population, MAX(total_cases) as highest_infection_count,  ROUND(Max((total_cases/population))*100,2) as percent_population_infected
From `main-reducer-337922.covid_data.covid_deaths`
WHERE continent is not null
Group by location, population
order by percent_population_infected desc

--4.  Countries with Highest Infection Rate compared to Population (fill NULL with 0)
WITH country_infection as(
Select location, population, date, MAX(total_cases) as highest_infection_count,  Max((total_cases/population))*100 as percent_population_infected
From `main-reducer-337922.covid_data.covid_deaths`
WHERE continent is not null
Group by location, population, date
order by percent_population_infected 
) 
SELECT location,population, date, 
IfNULL(highest_infection_count,0) as highest_infection_count, 
IfNULL(percent_population_infected,0) as percent_population_infected
FROM country_infection
order by percent_population_infected


-- Countries with Highest Death Count per Population

Select location, population, MAX(total_deaths) as total_death_cases,  
Max((total_deaths/population))*100 as percentage_deaths
From `main-reducer-337922.covid_data.covid_deaths`
WHERE continent is not null
Group by location, population
order by percentage_deaths desc




-- BREAKING THINGS DOWN BY CONTINENT

--2.  Showing CONTINENTS with the highest death

Select location, MAX(cast(total_deaths as int)) as total_death_counts
From `main-reducer-337922.covid_data.covid_deaths`
Where continent is null 
and location not in('World','International')
and location not like ('%income%')
and location not like ('%Union%')
Group by location
order by total_death_counts desc


--1.  GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From `main-reducer-337922.covid_data.covid_deaths`
where continent is not null 
-- Group By date
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From `main-reducer-337922.covid_data.covid_deaths` dea
Join `main-reducer-337922.covid_data.covid_vacination` vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- USE temp table to calculation vaccination %
WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinations
    FROM `main-reducer-337922.covid_data.covid_deaths` dea
    JOIN `main-reducer-337922.covid_data.covid_vacination` vac
        on dea.location = vac.location
        and dea.date = vac.date
    WHERE dea.continent is not null 
    -- ORDER BY 1,2,3
    )
SELECT *, rolling_people_vaccinations/population*100 as vaccination_percentage
FROM PopvsVac

-- create view to store data for later visualization
CREATE VIEW  `main-reducer-337922.covid_data.pop_vs_vac` as
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinations
    FROM `main-reducer-337922.covid_data.covid_deaths` dea
    JOIN `main-reducer-337922.covid_data.covid_vacination` vac
        on dea.location = vac.location
        and dea.date = vac.date
    WHERE dea.continent is not null 
    ORDER BY 1,2,3

