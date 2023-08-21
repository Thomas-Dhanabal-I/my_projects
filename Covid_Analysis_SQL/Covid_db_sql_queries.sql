/*
Covid 19 Data Exploration.Seperated whole file into Deaths and Vaccinations for my convinient

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- printing table info
SELECT TABLE_CATALOG,TABLE_SCHEMA,TABLE_NAME, COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 



SELECT *
FROM covid_db..CovidDeaths 
ORDER BY 3,4



-- Select data that we are going to be using
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM covid_db..CovidDeaths 
ORDER BY 1,2



-- Looking at total cases vs total deaths
SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercent
FROM covid_db..CovidDeaths 
--Where location like '%india%'
ORDER BY 1,2



-- Looking at total cases vs population
-- shows what population got affected by covid
SELECT location,date,total_cases,population,(total_cases/population)*100 as DeathPercent
FROM covid_db..CovidDeaths 
WHERE continent is not null
--Where location like '%india%'
ORDER BY 1,2



-- looking at countries with highest infection rate compared to population
SELECT location,population, MAX(total_cases) AS HighestInfectionCount,
			MAX(total_cases/population)*100	AS PercentPopulationInfected
FROM covid_db..CovidDeaths 
WHERE continent is not null
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC
 


 -- Countries with Highest Death Count per Population
 SELECT location,MAX(total_deaths) as TotalDeathCount
FROM covid_db..CovidDeaths 
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC 



-- continents with Highest Death Count per Population
SELECT continent,MAX(total_deaths) as TotalDeathCount
FROM covid_db..CovidDeaths 
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- Global total cases and total deaths 
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
               SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From covid_db..CovidDeaths
where continent is not null 

--date wise total cases and total deaths across world
select date,SUM(new_cases) as Total_cases,SUM(new_deaths) as Total_deaths,
					SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 as Death_percentage
FROM covid_db..CovidDeaths 
WHERE continent is not null
Group By date
order by date



--Looking at Total population vs vaccinations 
select Dea.continent,Dea.location,Dea.date,Dea.population,Vac.new_vaccinations,
SUM(Vac.new_vaccinations) over (partition by Dea.location order by Dea.location,Dea.date) as Tot_Vac
FROM covid_db..CovidDeaths Dea
join covid_db..CovidVaccinations Vac
on Dea.location=Vac.location and Dea.date=Vac.date
WHERE Dea.continent is not null 
order by 2,3



--Use CTE
with PopVsVac (continent,location,date,population,new_vaccinations,Tot_Vac)
as
(select Dea.continent,Dea.location,Dea.date,Dea.population,Vac.new_vaccinations,
SUM(Vac.new_vaccinations) over (partition by Dea.location order by Dea.location,Dea.date) as Tot_Vac
FROM covid_db..CovidDeaths Dea
join covid_db..CovidVaccinations Vac
on Dea.location=Vac.location and Dea.date=Vac.date
WHERE Dea.continent is not null 
--order by 2,3
)
select *,(Tot_Vac/population)*100 as Percent_of_Tot_Vac_in_tot_pop
from PopVsVac



--TEMP Table
drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(continent nvarchar(255), 
location nvarchar(255),
date date,
population numeric,
new_vaccinations numeric,
Tot_Vac numeric)
 
insert into #PercentPopulationVaccinated

select Dea.continent,Dea.location,Dea.date,Dea.population,Vac.new_vaccinations,
SUM(Vac.new_vaccinations) over (partition by Dea.location order by Dea.location,Dea.date) as Tot_Vac
FROM covid_db..CovidDeaths Dea
join covid_db..CovidVaccinations Vac
on Dea.location=Vac.location and Dea.date=Vac.date
--WHERE Dea.continent is not null 

select *,(Tot_Vac/population)*100 as Percent_of_Tot_Vac_in_tot_pop
from #PercentPopulationVaccinated




-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_db..CovidDeaths dea
Join covid_db..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
