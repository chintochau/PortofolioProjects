## MySQL exercises (questions from StrataScratch.com)
![螢幕擷取畫面 2022-08-06 092937](https://user-images.githubusercontent.com/28828270/183251039-06744f65-75e1-4b3b-84cf-8eb52461ff9f.jpg)


### Hard Q1. Monthly Percentage Difference
Given a table of purchases by date, calculate the month-over-month percentage change in revenue. The output should include the year-month date (YYYY-MM) and percentage change, rounded to the 2nd decimal point, and sorted from the beginning of the year to the end of the year.
The percentage change column will be populated from the 2nd month forward and can be calculated as ((this month's revenue - last month's revenue) / last month's revenue)*100.

Tables:  

~~~~
sf_transactions
Preview
id:int
created_at:datetime
value:int
purchase_id:int
~~~~

``` sql
with m as
(select  created_at month, sum(value) monthly_value
from sf_transactions
group by month(created_at))

select 
    DATE_FORMAT(month,'%Y-%m'), 
    round((monthly_value - LAG(monthly_value,1) OVER (order by month))*100/
    (LAG(monthly_value,1) OVER (order by month)),2) change_in_percentage
from m

-- OR

select 
    DATE_FORMAT(created_at,'%Y-%m') ,
    sum(value), 
    round((sum(value) - lag(SUM(value),1) over (order by month(created_at)))*100/
    lag(SUM(value),1) over (order by month(created_at)),2) percentage_change
from sf_transactions
group by month(created_at)


```


### Hard Q2. Premium vs Freemium
Find the total number of downloads for paying and non-paying users by date. Include only records where non-paying customers have more downloads than paying customers. The output should be sorted by earliest date first and contain 3 columns date, non-paying downloads, paying downloads.

Tables:  

~~~~
ms_user_dimension
Preview
user_id:int
acc_id:int
ms_acc_dimension
Preview
acc_id:int
paying_customer:varchar
ms_download_factsPreview
date:datetime
user_id:int
downloads:int
~~~~

``` sql
with all_table as(
    select u.user_id,a.acc_id,d.date,d.downloads,a.paying_customer 
    from ms_user_dimension u
    join 
    ms_acc_dimension a
    on u.acc_id = a.acc_id
    join
    ms_download_facts d
    on u.user_id = d.user_id)

select date,
    sum(case when paying_customer = 'yes' 
    then downloads else null end) paying_downloads,
    sum(case when paying_customer = 'no' 
    then downloads else null end) non_paying_downloads
    from all_table
    group by date
    having paying_downloads < non_paying_downloads
    order by date

```

### Hard Q3. Popularity Percentage
Find the popularity percentage for each user on Meta/Facebook. The popularity percentage is defined as the total number of friends the user has divided by the total number of users on the platform, then converted into a percentage by multiplying by 100.
Output each user along with their popularity percentage. Order records in ascending order by user id.
The 'user1' and 'user2' column are pairs of friends.

Tables:  

~~~~
facebook_friends
Preview
user1:int
user2:int
~~~~

``` sql
with m as (select * 
from facebook_friends a
union
select user2 as user1, user1 as user2
from facebook_friends b
order by user1) 

select user1, count(user2), count(user2)*100/(select count(distinct user2) from m)
from m
group by user1

--OR using over()

select user1, count(user2), count(user2)*100/count(user1) over() from
(select * 
from facebook_friends a
union
select user2 as user1, user1 as user2
from facebook_friends b
order by user1) t
group by user1

```

### Hard Q4. Marketing Campaign Success [Advanced]
You have a table of in-app purchases by user. Users that make their first in-app purchase are placed in a marketing campaign where they see call-to-actions for more in-app purchases. Find the number of users that made additional in-app purchases due to the success of the marketing campaign.


The marketing campaign doesn't start until one day after the initial in-app purchase so users that only made one or multiple purchases on the first day do not count, nor do we count users that over time purchase only the products they purchased on the first day.
Tables:  

~~~~
marketing_campaign
Preview
user_id:int
created_at:datetime
product_id:int
quantity:int
price:int
~~~~

``` sql
select count(distinct user_id) from
(    select 
        user_id,
        min(created_at) over(partition by user_id ) as m1, 
        min(created_at) over(partition by user_id,product_id ) as m2 
    FROM marketing_campaign) c
where m2>m1

-- OR

select
    count(distinct user_id) total_users
from
(
    select
        user_id, created_at, 
        DENSE_RANK() over(partition by user_id order by created_at) date_rnk,
        DENSE_RANK() over(partition by user_id, product_id order by created_at) product_rnk
    from marketing_campaign
) t1
where date_rnk > 1 and product_rnk = 1
```

### Hard Q5. Top 5 States With 5 Star Businesses
Find the top 5 states with the most 5 star businesses. Output the state name along with the number of 5-star businesses and order records by the number of 5-star businesses in descending order. In case there are ties in the number of businesses, return all the unique states. If two states have the same result, sort them in alphabetical order.

Tables:  
yelp_business
Preview
business_id:varchar
name:varchar
neighborhood:varchar
address:varchar
city:varchar
state:varchar
postal_code:varchar
latitude:float
longitude:float
stars:float
review_count:int
is_open:int
categories:varchar
~~~~

~~~~

``` sql
select state, number,ranking from
(select state,count(stars) number,rank() over (order by count(stars) desc) ranking  from yelp_business
where stars = 5
group by state
) t
where ranking <=5
```


### Hard Q6. Counting Instances in Text
Find the number of times the words 'bull' and 'bear' occur in the contents. We're counting the number of times the words occur so words like 'bullish' should not be included in our count.
Output the word 'bull' and 'bear' along with the corresponding number of occurrences.

Tables:  

~~~~
google_file_store
Preview
filename:varchar
contents:varchar
~~~~

``` sql
with m as 
(SELECT 
    filename,
    contents,    
    sum(ROUND (   
        (
            LENGTH(contents)
            - LENGTH( REPLACE ( contents, "bull ", "") ) 
        ) / LENGTH("bull ")        
    )) AS bull_count,   
    sum(ROUND (   
        (
            LENGTH(contents)
            - LENGTH( REPLACE ( contents, "bear ", "") ) 
        ) / LENGTH("bear ")        
    )) as bear_count  
from google_file_store)

select 'bull',bull_count as value from m
union all 
select 'bear',bear_count as value from m
```


### Hard Q7. Host Popularity Rental Prices
You’re given a table of rental property searches by users. The table consists of search results and outputs host information for searchers. Find the minimum, average, maximum rental prices for each host’s popularity rating. The host’s popularity rating is defined as below:0 reviews: New
1 to 5 reviews: Rising
6 to 15 reviews: Trending Up
16 to 40 reviews: Popular
more than 40 reviews: Hot


Tip: The id column in the table refers to the search ID. You'll need to create your own host_id by concating price, room_type, host_since, zipcode, and number_of_reviews.


Output host popularity rating and their minimum, average and maximum rental prices.

Tables:  

~~~~
airbnb_host_searches
Preview
id:int
price:float
property_type:varchar
room_type:varchar
amenities:varchar
accommodates:int
bathrooms:int
bed_type:varchar
cancellation_policy:varchar
cleaning_fee:bool
city:varchar
host_identity_verified:varchar
host_response_rate:varchar
host_since:datetime
neighbourhood:varchar
number_of_reviews:int
review_scores_rating:float
zipcode:int
bedrooms:int
beds:int
~~~~

``` sql
with m as(select 
    concat(price, room_type, host_since, zipcode,number_of_reviews) host_id,
    price,
    Case 
    when number_of_reviews > 40 then 'Hot' 
    when number_of_reviews >= 16 then 'Popular' 
    when number_of_reviews >= 6 then 'Trending Up' 
    when number_of_reviews >= 1 then 'Rising' 
    else 'New' end popularity
from airbnb_host_searches
group by host_id)

select 
    popularity as host_pop_rating, 
    min(price) as min_price,
    avg(price) as min_price,
    max(price) as max_price
    from m
group by 1
```

### Q1. Workers With The Highest Salaries - Medium
Find the titles of workers that earn the highest salary. Output the highest-paid title or multiple titles that share the highest salary.

Tables:  
~~~~
worker
Preview
worker_id:int
first_name:varchar
last_name:varchar
salary:int
joining_date:datetime
department:varchar

title
Preview
worker_ref_id:int
worker_title:varchar
affected_from:datetime
~~~~

``` sql
select  t.worker_title from worker w
join title t
on w.worker_id = t.worker_ref_id
where salary = (select max(salary) from worker)
```

### Q2. Users By Average Session Time - Medium
Calculate each user's average session time. A session is defined as the time difference between a page_load and page_exit. For simplicity, assume a user has only 1 session per day and if there are multiple of the same events on that day, consider only the latest page_load and earliest page_exit. Output the user_id and their average session time.


Tables:  
~~~~
facebook_web_log
Preview
user_id:int
timestamp:datetime
action:varchar
~~~~

``` sql
SELECT user_id, AVG(TIMESTAMPDIFF(SECOND, load_time, exit_time)) AS session_time
FROM (
    SELECT 
        DATE(timestamp), 
        user_id, 
        MAX(IF(action = 'page_load', timestamp, NULL)) as load_time,
        MIN(IF(action = 'page_exit', timestamp, NULL)) as exit_time
    FROM facebook_web_log
    GROUP BY 1, 2
) t 
GROUP BY user_id
HAVING session_time IS NOT NULL;
```

### Q3. Finding User Purchases - Medium
Write a query that'll identify returning active users. A returning active user is a user that has made a second purchase within 7 days of any other of their purchases. Output a list of user_ids of these returning active users.

Tables:  
~~~~
amazon_transactions
Preview
id:int
user_id:int
item:varchar
created_at:datetime
revenue:int
~~~~

``` sql
SELECT DISTINCT t1.user_id
FROM amazon_transactions AS t1, amazon_transactions AS t2
WHERE t1.user_id = t2.user_id AND
ABS (datediff(t1.created_at, t2.created_at)) <=7 AND
t1.id != t2.id
```


### Q4. Salaries Differences - Easy
Write a query that calculates the difference between the highest salaries found in the marketing and engineering departments. Output just the absolute difference in salaries.


Tables:  
~~~~
db_employee
Preview
id:int
first_name:varchar
last_name:varchar
salary:int
department_id:int
email:datetime

db_dept
Preview
id:int
department:varchar
~~~~

``` sql
select ABS((select max(salary)
from db_employee as a
left join db_dept as b
on a.department_id = b.id
where department = 'marketing') - 
(select max(salary)
from db_employee as a
left join db_dept as b
on a.department_id = b.id
where department = 'engineering') ) salary_difference

//OR//

with db as (
select salary,department from db_employee as e join db_dept as d
on e.department_id = d.id
)

select abs(max(a.salary) - max(b.salary)) as salary_difference from db a join db b
where a.department = 'marketing' and b.department = 'engineering'
```


### Q5. Finding Updated Records
We have a table with employees and their salaries, however, some of the records are old and contain outdated salary information. Find the current salary of each employee assuming that salaries increase each year. Output their id, first name, last name, department ID, and current salary. Order your list by employee ID in ascending order.

Tables:  
~~~~
ms_employee_salary
Preview
id:int
first_name:varchar
last_name:varchar
salary:int
department_id:int
~~~~

``` sql
select id,first_name,last_name,department_id,max(salary) as salary 
from ms_employee_salary
group by id
order by id
```


### Q6. Number of Streets Per Zip Code
Find the number of different street names for each postal code, for the given business dataset. For simplicity, just count the first part of the name if the street name has multiple words.


For example, East Broadway can be counted as East. East Main and East Broadly may be counted both as East, which is fine for this question.


Counting street names should also be case insensitive, meaning FOLSOM should be counted the same as Folsom. Lastly, consider that some street names have different structures. For example, Pier 39 is the same street as 39 Pier,  your solution should count both situations as Pier street.


Output the result along with the corresponding postal code. Order the result based on the number of streets in descending order and based on the postal code in ascending order.

Tables:  
~~~~
sf_restaurant_health_violations
Preview
business_id:int
business_name:varchar
business_address:varchar
business_city:varchar
business_state:varchar
business_postal_code:float
business_latitude:float
business_longitude:float
business_location:varchar
business_phone_number:float
inspection_id:varchar
inspection_date:datetime
inspection_score:float
inspection_type:varchar
violation_id:varchar
violation_description:varchar
risk_category:varchar
~~~~

``` sql
select count(distinct street_name) as number,business_postal_code as postal_code
from (select 
    case when business_address REGEXP "^[0-9]"
    then SUBSTRING_INDEX(SUBSTRING_INDEX(business_address,' ', 2),' ', -1) 
    else SUBSTRING_INDEX(business_address,' ', 1) end as street_name,
    business_address,
    business_postal_code 
from sf_restaurant_health_violations) as t
where business_postal_code IS NOT NULL
group by business_postal_code
order by number desc
```

### Q7. Bikes Last Used
Find the last time each bike was in use. Output both the bike number and the date-timestamp of the bike's last use (i.e., the date-time the bike was returned). Order the results by bikes that were most recently used.

Tables:  
~~~~
dc_bikeshare_q1_2012
Preview
duration:varchar
duration_seconds:int
start_time:datetime
start_station:varchar
start_terminal:int
end_time:datetime
end_station:varchar
end_terminal:int
bike_number:varchar
rider_type:varchar
id:int
~~~~

``` sql
select MAX(end_time) as last_used, bike_number 
from dc_bikeshare_q1_2012
group by bike_number
order by last_used
```

### Q8. Ranking Most Active Guests
Rank guests based on the number of messages they've exchanged with the hosts. Guests with the same number of messages as other guests should have the same rank. Do not skip rankings if the preceding rankings are identical.
Output the rank, guest id, and number of total messages they've sent. Order by the highest number of total messages first.

Tables:  
~~~~
airbnb_contacts
Preview
id_guest:varchar
id_host:varchar
id_listing:varchar
ts_contact_at:datetime
ts_reply_at:datetime
ts_accepted_at:datetime
ts_booking_at:datetime
ds_checkin:datetime
ds_checkout:datetime
n_guests:int
n_messages:int
~~~~

``` sql
select dense_rank() OVER (
    ORDER BY sum(n_messages) desc
) as RANKS,id_guest, sum(n_messages) as total
from airbnb_contacts
group by id_guest

```


### Q9. Number Of Units Per Nationality
Find the number of apartments per nationality that are owned by people under 30 years old.
Output the nationality along with the number of apartments.
Sort records by the apartments count in descending order.

Tables:  
~~~~
airbnb_hosts
Preview
host_id:int
nationality:varchar
gender:varchar
age:int

airbnb_units
Preview
host_id:int
unit_id:varchar
unit_type:varchar
n_beds:int
n_bedrooms:int
country:varchar
city:varchar
~~~~

``` sql
select count(distinct unit_id) cnt,nationality from airbnb_hosts h
join airbnb_units u
on h.host_id = u.host_id
where h.age < 30 and u.unit_type = 'Apartment'
group by nationality
order by cnt desc
```


### Q10. Count the number of movies that Abigail Breslin nominated for oscar
Count the number of movies that Abigail Breslin was nominated for an oscar.

Tables:  
~~~~
oscar_nominees
Preview
year:int
category:varchar
nominee:varchar
movie:varchar
winner:bool
id:int
~~~~

``` sql
select count(*) from oscar_nominees
where nominee = 'Abigail Breslin'
```


### Q11. Find all posts which were reacted to with a heart 
Find all posts which were reacted to with a heart. For such posts output all columns from facebook_posts table.

Tables:  
~~~~
facebook_reactions
Preview
poster:int
friend:int
reaction:varchar
date_day:int
post_id:int

facebook_posts
Preview
post_id:int
poster:int
post_text:varchar
post_keywords:varchar
post_date:datetime
~~~~

``` sql
select distinct p.post_id, p.poster, p.post_text, p.post_keywords, p.post_date from facebook_reactions r
join facebook_posts p
on r.post_id = p.post_id
where r.reaction = 'heart'
```


### Q12. Find matching hosts and guests in a way that they are both of the same gender and nationality
Find matching hosts and guests pairs in a way that they are both of the same gender and nationality.
Output the host id and the guest id of matched pair.

Tables:  
~~~~
airbnb_hosts
Preview
host_id:int
nationality:varchar
gender:varchar
age:int
airbnb_guests
Preview
guest_id:int
nationality:varchar
gender:varchar
age:int
~~~~

``` sql
-- since there are duplicate values on hosts table, perform select distinct first
select * from (select distinct host_id, nationality, gender, age from airbnb_hosts) as h
join airbnb_guests g
on h.nationality = g.nationality AND h.gender = g.gender
```


### Q13. Income By Title and Gender
Find the average total compensation based on employee titles and gender. Total compensation is calculated by adding both the salary and bonus of each employee. However, not every employee receives a bonus so disregard employees without bonuses in your calculation. Employee can receive more than one bonus.
Output the employee title, gender (i.e., sex), along with the average total compensation.

Tables:  
~~~~
sf_employee
Preview
id:int
first_name:varchar
last_name:varchar
age:int
sex:varchar
employee_title:varchar
department:varchar
salary:int
target:int
email:varchar
city:varchar
address:varchar
manager_id:int
sf_bonus
Preview
worker_ref_id:int
bonus:int
bonus_date:datetime
~~~~

``` sql
select employee_title,sex, avg(total) from
(select *,sum(distinct e.salary) + sum(b.bonus) as total from sf_employee e
join sf_bonus b
on e.id = b.worker_ref_id
group by e.id) t
group by employee_title
```


<!--Template-->

### Q2. 


Tables:  

~~~~

~~~~

``` sql

```
