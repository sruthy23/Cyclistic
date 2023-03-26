--Consolidate 12 months of data into a single table for query
-- Add a column for season 
-- Calculate the median trip duration for annual members vs casual riders
WITH trips(ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name,
end_station_id, start_lat, start_lng, end_lat, end_lng, member_casual, ride_length, day_of_week, Median, season) AS 
  (SELECT *, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY DATEDIFF(second, 0, ride_length)) OVER(PARTITION BY member_casual), 
   CASE WHEN MONTH(started_at) IN (6,7,8) THEN 'summer'
		WHEN MONTH(started_at) IN (9, 10, 11) THEN 'autumn'
		WHEN MONTH(started_at) IN (12, 1, 2) THEN 'winter'
		ELSE 'spring' END  
   FROM (SELECT * FROM trips06
	UNION ALL
	SELECT * FROM trips07
	UNION ALL
	SELECT * FROM trips08
	UNION ALL
	SELECT * FROM trips09
	UNION ALL
	SELECT * FROM trips10
	UNION ALL
	SELECT * FROM trips11
	UNION ALL
	SELECT * FROM trips12
	UNION ALL
	SELECT * FROM trips01
	UNION ALL
	SELECT * FROM trips02
	UNION ALL
	SELECT * FROM trips03
	UNION ALL
	SELECT * FROM trips04
	UNION ALL
	SELECT * FROM trips05) AS t)
	
	-- Calculate mean, median and maximum ride_length for annual members vs casual riders
	SELECT DISTINCT member_casual, AVG(CAST(DATEDIFF(second, 0, ride_length)AS FLOAT)) AS Mean, MAX(ride_length) AS Maximum, AVG(Median) AS Median 
	FROM trips 
	GROUP BY member_casual;

	--Calculate average ride_length for annual members vs casual riders by day of the week
	SELECT DISTINCT member_casual, day_of_week, ROUND(AVG(CAST(DATEDIFF(second, 0, ride_length)AS FLOAT)), 2) AS Mean   
	FROM trips
	GROUP BY member_casual, day_of_week 
	ORDER BY day_of_week, member_casual;

	-- Compare number of rides booked by members vs casual riders by day of the week
	SELECT DISTINCT member_casual, day_of_week, COUNT(ride_id) AS Number_of_rides    
	FROM trips
	GROUP BY member_casual, day_of_week 
	ORDER BY member_casual, Number_of_rides DESC;

	-- Compare number of rides booked by members vs casual riders in different seasons
	SELECT DISTINCT season, member_casual, COUNT(ride_id) FROM trips GROUP BY season, member_casual ORDER BY season, COUNT(ride_id) DESC;

	-- Compare average ride_length of members vs casual riders in different seasons
	SELECT DISTINCT season, member_casual, AVG(CAST(DATEDIFF(second, 0, ride_length)AS FLOAT)) AS Mean FROM trips GROUP BY season, member_casual ORDER BY season, member_casual;



-- Creating view for later visualizations
-- Create View of total trips
Create View Total_Trips AS
SELECT *, DATENAME(DW,started_at) AS day, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY DATEDIFF(second, 0, ride_length)) OVER(PARTITION BY member_casual) AS median, 
   CASE WHEN MONTH(started_at) IN (6,7,8) THEN 'summer'
		WHEN MONTH(started_at) IN (9, 10, 11) THEN 'autumn'
		WHEN MONTH(started_at) IN (12, 1, 2) THEN 'winter'
		ELSE 'spring' END AS season  
FROM (SELECT * FROM trips06
UNION ALL
SELECT * FROM trips07
UNION ALL
SELECT * FROM trips08
UNION ALL
SELECT * FROM trips09
UNION ALL
SELECT * FROM trips10
UNION ALL
SELECT * FROM trips11
UNION ALL
SELECT * FROM trips12
UNION ALL
SELECT * FROM trips01
UNION ALL
SELECT * FROM trips02
UNION ALL
SELECT * FROM trips03
UNION ALL
SELECT * FROM trips04
UNION ALL
SELECT * FROM trips05) AS t;

-- Create View of average length for annual members and casual riders by day of the week
Create View Average_RideLength_DayOfWeek AS 
SELECT DISTINCT member_casual, day, ROUND(AVG(CAST(DATEDIFF(MINUTE, 0, ride_length)AS FLOAT)), 2) AS Mean   
FROM Total_Trips 
GROUP BY member_casual, day 
-- ORDER BY day_of_week, member_casual;
SELECT * FROM Average_RideLength_DayOfWeek;

-- Create View of number of rides booked by annua members and casual riders by day of the week
Create View Rides_Booked_DayOfWeek AS 
SELECT DISTINCT member_casual, day, COUNT(ride_id) AS Number_of_rides    
FROM Total_Trips 
GROUP BY member_casual, day; 
-- ORDER BY member_casual, Number_of_rides DESC;
SELECT * FROM Rides_Booked_DayOfWeek;

-- Create View for overall stats
Create View Overall_Stats AS
SELECT COUNT(*) AS total_users, (SELECT COUNT(*) FROM Total_Trips WHERE member_casual = 'member') AS members, (SELECT COUNT(*) FROM Total_Trips WHERE member_casual = 'casual') AS casual 
FROM Total_Trips;
SELECT * FROM Overall_Stats;

-- Create view for stats with percentages
Create View Overall_Stats_Percent AS
SELECT total_users AS 'Total Users', members AS 'Annual Members', CAST(ROUND(((members/CAST(total_users AS float))*100), 0) AS int) AS "% of Annual Members", casual AS 'Casual riders', CAST(ROUND(((casual/CAST(total_users AS float))*100), 0) AS int)  AS '% of Casual riders'
FROM Overall_Stats;
SELECT * FROM Overall_Stats_Percent;