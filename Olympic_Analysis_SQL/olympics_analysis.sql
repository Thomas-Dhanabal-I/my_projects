=======================================================================================================================================================================
                                                 --OLMPIC DATA ANALYSIS--
=======================================================================================================================================================================
select * from olympics_history
select * from olympics_history_noc_regions

--1. How many olympics games have been held?

select count(distinct games) as total_olympic_games
from olympics_history;

--2. List down all Olympics games held so far. (Data issue at 1956-"Summer"-"Stockholm")

select distinct oh.year,oh.season,oh.city
from olympics_history oh
order by year;


--3. Mention the total no of nations who participated in each olympics game?
soln 1:

with all_countries as
(select games, nr.region
from olympics_history oh
join olympics_history_noc_regions nr ON nr.noc = oh.noc
group by games, nr.region)
select games, count(1) as total_countries
from all_countries
group by games
order by games;

soln 2:

select distinct games,count(distinct region)
from olympics_history ae
join olympics_history_noc_regions nr on ae.noc=nr.noc
group by games
order by games

--4. Which year saw the highest and lowest no of countries participating in olympics

with all_countries as
        (select games, nr.region
        from olympics_history oh
        join olympics_history_noc_regions nr ON nr.noc=oh.noc
        group by games, nr.region),
    tot_countries as
        (select games, count(1) as total_countries
        from all_countries
        group by games)
select distinct
concat(first_value(games) over(order by total_countries)
, ' - '
, first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
concat(first_value(games) over(order by total_countries desc)
, ' - '
, first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
from tot_countries
order by 1;


--5. Which nation has participated in all of the olympic games
with tot_games as
        (select count(distinct games) as total_games
        from olympics_history),
    countries as
        (select games, nr.region as country
        from olympics_history oh
        join olympics_history_noc_regions nr ON nr.noc=oh.noc
        group by games, nr.region),
    countries_participated as
        (select country, count(1) as total_participated_games
        from countries
        group by country)
select cp.*
from countries_participated cp
join tot_games tg on tg.total_games = cp.total_participated_games
order by 1;

--6. Identify the sport which was played in all summer olympics.
with t1 as
    (select count(distinct games) as total_games
    from olympics_history where season = 'Summer'),
    t2 as
    (select distinct games, sport
    from olympics_history where season = 'Summer'),
    t3 as
    (select sport, count(1) as no_of_games
    from t2
    group by sport)
select *
from t3
join t1 on t1.total_games = t3.no_of_games;


--7. Which Sports were just played only once in the olympics.
with t1 as
    (select distinct games, sport
    from olympics_history),
    t2 as
    (select sport, count(1) as no_of_games
    from t1
    group by sport)
select t2.*, t1.games
from t2
join t1 on t1.sport = t2.sport
where t2.no_of_games = 1
order by t1.sport;


--8. Fetch the total no of sports played in each olympic games.
with t1 as
(select distinct games, sport
from olympics_history),
t2 as
(select games, count(1) as no_of_sports
from t1
group by games)
select * from t2
order by no_of_sports desc;


--9. Fetch oldest athletes to win a gold medal
with temp as
    (select name,sex,cast(case when age = 'NA' then '0' else age end as int) as age
        ,team,games,city,sport, event, medal
    from olympics_history),
ranking as
    (select *, rank() over(order by age desc) as rnk
    from temp
    where medal='Gold')
select *
from ranking
where rnk = 1;


--10. Find the Ratio of male and female athletes participated in all olympic games.
 
with     sex_cnt as 
(select sex,count(*) as cnt
from olympics_history
group by sex),
cnt_with_rn as 
(select *,ROW_NUMBER() over (order by cnt desc) as rn
from sex_cnt),
male_count as 
        (select cnt from cnt_with_rn where rn=1),
female_count as 
        (select cnt  from cnt_with_rn where rn=2)
select concat('1:',
cast(round(CONVERT(float, male_count.cnt) / female_count.cnt,2)as varchar) )as ratio
from male_count,female_count


--11. Top 5 athletes who have won the most gold medals.
with t1 as
    (select name, team, count(1) as total_gold_medals
    from olympics_history
    where medal = 'Gold'
    group by name, team
    order by total_gold_medals desc),
t2 as
    (select *, dense_rank() over (order by total_gold_medals desc) as rnk
    from t1)
select name, team, total_gold_medals
from t2
where rnk <= 5;


--12. Top 5 athletes who have won the most medals (gold/silver/bronze).
with t1 as
    (select name, team, count(1) as total_medals
    from olympics_history
    where medal in ('Gold', 'Silver', 'Bronze')
    group by name, team
    order by total_medals desc),
t2 as
    (select *, dense_rank() over (order by total_medals desc) as rnk
    from t1)
select name, team, total_medals
from t2
where rnk <= 5;

	
--13. Top 5 most successful countries in olympics. Success is defined by no of medals won.
with t1 as
    (select nr.region, count(1) as total_medals
    from olympics_history oh
    join olympics_history_noc_regions nr on nr.noc = oh.noc
    where medal <> 'NA'
    group by nr.region
    order by total_medals desc),
t2 as
    (select *, dense_rank() over(order by total_medals desc) as rnk
    from t1)
select *
from t2
where rnk <= 5;




--14. List down total gold, silver and broze medals won by each country.

SELECT country,
COALESCE(SUM(CASE WHEN medal = 'Gold' THEN total_medals END), 0) AS gold,
COALESCE(SUM(CASE WHEN medal = 'Silver' THEN total_medals END), 0) AS silver,
COALESCE(SUM(CASE WHEN medal = 'Bronze' THEN total_medals END), 0) AS bronze
FROM
(
SELECT nr.region AS country, medal, COUNT(1) AS total_medals
FROM olympics_history oh
JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
WHERE medal <> 'NA'
GROUP BY nr.region, medal
) AS crosstab
GROUP BY country
ORDER BY country



--15. List down total gold, silver and broze medals won by each country corresponding to each olympic games.

select games,region,
coalesce(sum(case when medal='Gold' then tot_medals end),0) as gold,
coalesce(sum(case when medal='silver' then tot_medals end),0) as silver,
coalesce(sum(case when medal='bronze' then tot_medals end),0) as bronze
from
(
select games,region,medal,count(*) as tot_medals
from olympics_history a
join olympics_history_noc_regions b on a.noc=b.noc
where medal is not null
group by games,region,medal
)x
group by games,region
order by games,region




--16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.

with tab as
(
select games,region,
coalesce(sum(case when medal='Gold' then tot_medals end),0) as gold,
coalesce(sum(case when medal='silver' then tot_medals end),0) as silver,
coalesce(sum(case when medal='bronze' then tot_medals end),0) as bronze
from
(
select games,region,medal,count(*) as tot_medals
from olympics_history a
join olympics_history_noc_regions b on a.noc=b.noc
where medal is not null
group by games,region,medal
)x
group by games,region
)
select distinct games,
concat(FIRST_VALUE(region) over (partition by games order by gold   desc) ,'-',
FIRST_VALUE(gold)   over (partition by games order by gold   desc)) as country_gold,
concat(FIRST_VALUE(region) over (partition by games order by silver desc) ,'-',
FIRST_VALUE(silver) over (partition by games order by silver desc)) as country_silver,
concat(FIRST_VALUE(region) over (partition by games order by bronze desc) ,'-',
FIRST_VALUE(bronze) over (partition by games order by bronze desc)) as country_bronze
from tab
order by games




--17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

with tab as
(
select games,region,
coalesce(sum(case when medal='Gold' then tot_medals end),0) as gold,
coalesce(sum(case when medal='silver' then tot_medals end),0) as silver,
coalesce(sum(case when medal='bronze' then tot_medals end),0) as bronze,
sum(case when medal in ('Gold', 'Silver', 'Bronze') then tot_medals end) as total_medals
from
(
select games,region,medal,count(*) as tot_medals
from olympics_history a
join olympics_history_noc_regions b on a.noc=b.noc
where medal is not null
group by games,region,medal
)x
group by games,region
)
select distinct games,
concat(FIRST_VALUE(region) over (partition by games order by gold   desc) ,'-',
FIRST_VALUE(gold)   over (partition by games order by gold   desc)) as country_gold,
concat(FIRST_VALUE(region) over (partition by games order by silver desc) ,'-',
FIRST_VALUE(silver) over (partition by games order by silver desc)) as country_silver,
concat(FIRST_VALUE(region) over (partition by games order by bronze desc) ,'-',
FIRST_VALUE(bronze) over (partition by games order by bronze desc)) as country_bronze,
concat(FIRST_VALUE(region) over (partition by games order by total_medals desc) ,'-',
FIRST_VALUE(total_medals) over (partition by games order by total_medals desc)) as most_medals
from tab
order by games


--18. Which countries have never won gold medal but have won silver/bronze medals?
select *
from
(select region,
coalesce(sum(case when medal='Gold' then tot_medals end),0) as gold,
coalesce(sum(case when medal='silver' then tot_medals end),0) as silver,
coalesce(sum(case when medal='bronze' then tot_medals end),0) as bronze
from 
(select region,medal,count(*) as tot_medals
from olympics_history a
join olympics_history_noc_regions b on a.noc=b.NOC
where medal is not null
group by  region,medal)x
group by region
)x
where gold=0 
order by region



--19. In which Sport/event, India has won highest medals.
with t1 as
    (select sport, count(1) as total_medals
    from olympics_history
    where medal <> 'NA'
    and team = 'India'
    group by sport
    order by total_medals desc),
t2 as
    (select *, rank() over(order by total_medals desc) as rnk
    from t1)
select sport, total_medals
from t2
where rnk = 1;

--20. Break down all olympic games where india won medal for Hockey and how many medals in each olympic games
select team, sport, games, count(1) as total_medals
from olympics_history
where medal <> 'NA'
and team = 'India' and sport = 'Hockey'
group by team, sport, games
order by total_medals desc;
