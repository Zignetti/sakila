-- investigating the sakila database

-- number of tables
select count(*) as totalTables
from information_schema.tables
where table_schema='sakila';


-- number of columns
select count(*) as totalColumns
from information_schema.columns
where table_name='actor';

select * from actor;

-- copy the actor table for safe manipulation

create table actor_copy
like actor;

insert into actor_copy
select *
from actor;

--  investigate the copied actor table

select count(*) as numRows
from actor_copy;
-- has 200 rows

select count(*) as numColumns
from information_schema.columns
where table_name='actor_copy';
-- has 4 columns

-- check for missing values
select count(*) as MissingTotal,
count(if(actor_id is null,1,null)) as missingID,
count(if(first_name is null or first_name='',1,null)) as missingFirstName,
count(if(last_name is null or last_name='',1,null)) as missingLastName,
count(if(last_update is null,1,null)) as missingDates
from actor_copy;

-- no missing values in any of the columns

-- set all names to lower case

select lower(first_name), lower(last_name)
from actor_copy;

-- set the first letter of the name to upper and all else lower
select concat(upper(substring(first_name,1,1)), lower(substring(first_name,2))) as formatedFirstName
from actor_copy;

select
	   concat(upper(substring(last_name,1,1)),lower(substring(last_name,2))) as formatedLastName
from actor_copy;

-- update the actor table
set sql_safe_updates=0;
update actor_copy
set first_name = concat(upper(substring(first_name,1,1)), lower(substring(first_name,2)));
set sql_safe_updates=1;

set sql_safe_updates=0;
update actor_copy
set last_name = concat(upper(substring(last_name,1,1)),lower(substring(last_name,2)));
set sql_safe_updates=1;

-- select only the year from the time stamp

select cast(regexp_substr(last_update,'[0-9]{4}') as signed integer) as updateYear
from actor_copy;

-- final table ready for join          
select * from actor_copy;

--------  address table-----------------------
create table address_copy
like address;

insert into address_copy
select *
from address;

-- investigate the address table

select * from address_copy;

-- drop column address2 due to high number of missing values
select count(*) as missingValues,
round((sum(if(address2 is null,1,null))*100/count(*)),2) as missing_percentage_address2
from address_copy;

alter table address_copy
drop column  address2;

-- split the address column into house number and street
select 
trim(substring_index(address,' ',1)) as house_number, 
trim(substring(address, length(substring_index(address,' ',1)) +2)) as street
from address_copy;

-- update the address table

alter table address_copy
add column house_number varchar(50),
add column street varchar(100);

update address_copy
set house_number = trim(substring_index(address,' ',1)) , 
 street= trim(substring(address, length(substring_index(address,' ',1)) +2));
 
alter table address_copy
drop column address;

-- clean the district column

-- remove special characters
select * 
from address_copy
where district regexp '[\\*\\:\\*\\(\\)\\,\\.]';


select trim(replace(replace(district,'(City)',' '),'Mxico','Mexico'))
from address_copy;

update address_copy
set district= trim(replace(district,'(City)',''));


update address_copy
set district= trim(replace(district,'Mxico','Mexico'));


-- check for missing rows in district column
select * 
from address_copy
where district is null or district='';

-- we have missing values in district column where city id is 121,493 and 583
 

-- we will need to inspect the city table for any related info
select *
from city
where city_id = 121 or city_id=493 or city_id=583;

-- assumption: that the district is within the city, hence we can replace the missing
-- districts with their city names

select replace(district,' ','Città del Vaticano')
from address_copy
where city_id=121;

update address_copy
set district= 'Città del Vaticano'
where city_id=121;

select replace(district,' ','South Hill')
from address_copy
where city_id=493;

update address_copy
set district= 'South Hill'
where city_id=493;

select replace(district,'','Yangor')
from address_copy
where city_id=583;

update address_copy
set district= 'Yangor'
where city_id=583;

-- also drop the first 2 rows as they appear as duplicate of row 3 and 4

delete from address_copy
where address_id = 1 or address_id=2;

-- the clean address table
select * 
from address_copy;

---------------- next is the category table-----------------

select * from category;

-- looks okay here

----------  next we expect the city table-------------

select * from city;

-- create a copy of the city table

create table city_copy
like city;

insert into city_copy
select * from city;

-- check for duplicates
select city, COUNT(*) AS count
from city_copy
group by city
having COUNT(*) > 1;

-- shows the city 'London' is duplicated

select * 
from city_copy
where city = 'London';

-- shows we have London appearing twice with city_id and country_id of 312,102 and 313,20 respectively
-- we need to inspect the country table

select * 
from country
where country_id= 102 or country_id=20;
-- this confirm its not a duplicate as one is a Canada city and the other is in United kingdom


-- remove the special characters and coding
select *
from city_copy
where city regexp '[//*)//(@//]';

-- standardise the city column to primary name by removing anything before the parenthesis
set sql_safe_updates=0;
update city_copy
set city= trim(substring_index(city,'(',1));
set sql_safe_updates=1;

-- the clean city table
select*
from city_copy;

----- next is country table----------------------------

select * from country;

-- check for duplicates
select country, count(*) as duplicates
from country
group by country
having count(*)>1;

-- no duplicates

-- check for spelling errors

select *
from country
where country regexp '[//*//@+-//(//):]';

-- create a copy of the table

create table country_copy
like country;

insert into country_copy
select* from country;

--  standardise country name to the legacy or first name
set sql_safe_updates=0;
update country_copy
set country= trim(substring_index(country,',',1));
set sql_safe_updates=1;

-- keep all names before parenthesis, makes it more readeable and consistent
set sql_safe_updates=0;
update country_copy
set country= trim(substring_index(country,'(',1));
set sql_safe_updates=1;

-- clean country table
select * from country_copy;

------ next is the customer table-----------------
-- inspect for missing values, duplicates and standardise the names
-- by capitalising the first letter and converting the rest to lower letters
-- keeping all the emails in lower letters

-- create a copy for safe manipulation
create table customer_copy
like customer;

insert into customer_copy
select * from customer;

-- check for missing values
select count(*) as count,
count(if(customer_id is null,1,null)) as missing_customer_id,
count(if(store_id is null,1,null)) as missing_store_id,
count(if(first_name is null or first_name='',1,null)) as missing_firstName,
count(if(last_name is null or last_name='',1,null)) as missing_lastName,
count(if(email is null or email='',1,null)) as missing_email,
count(if(address_id is null,1,null)) as missing_address_id,
count(if(active is null,1,null)) as missing_active
from customer_copy;

-- no missing values

-- check for duplicates in the first and last name columns

select first_name, last_name, count(*) as duplicates
from customer_copy
group by first_name, last_name
having count(*)>1;

-- no duplicates

-- convert to lower letter
select concat(upper(trim(substring(first_name,1,1))),
		lower(substring(first_name,2))) as NewFirstName
from customer_copy;

select concat(upper(trim(substring(last_name,1,1))),
		lower(substring(last_name,2))) as NewlastName
from customer_copy;

set sql_safe_updates=0;
update customer_copy
set first_name= concat(upper(trim(substring(first_name,1,1))),
		lower(substring(first_name,2)));        
set sql_safe_updates=1;
        
set sql_safe_updates=0;
update customer_copy
set last_name =concat(upper(trim(substring(last_name,1,1))),
		lower(substring(last_name,2)));
set sql_safe_updates=1;

-- keep all the emails in lower letters

set sql_safe_updates=0;
update customer_copy
set email= lower(email);
set sql_safe_updates=1;


-- the clean customer table
select *
from customer_copy;


----------- next film table------------------------

-- create a copy of the table
create table film_copy
like film;

insert into film_copy
select* from film;

-- check for missing values
select count(*) as missingTotal,
count(if(film_id is null,1,null)) as missingFilmId,
count(if(title is null or title='',1,null)) as missingTitle,
count(if(release_year is null,1,null)) as missingReleaseYear,
count(if(language_id is null,1,null)) as missingLanguageId,
count(if(original_language_id is null,1,null)) as missingOriginalLanguageId,
count(if(rental_duration is null,1,null)) as missingrentalDuration,
count(if(rental_rate is null,1,null)) as missingRentalRate,
count(if(length is null,1,null)) as missingLength,
count(if(replacement_cost is null,1,null)) as missingreplacementCost,
count(if(rating is null,1,null)) as missingRating,
count(if(special_features is null,1,null)) as missingSpecialFeatures,
count(if(youth is null,1,null)) as missingYouth
from film_copy;

-- we have 100% missing values in the original language and youth columns
-- we will drop these 2 columns as well as the description and sepecial features columns

alter table film_copy
drop column description;

alter table film_copy
drop column original_language_id;

alter table film_copy
drop column special_features;

alter table film_copy
drop column youth;

-- standardise the title column for consistency
set sql_safe_updates=0;
update film_copy
set title	= concat(
			upper(left(title,1)), lower(substring(title,2,locate(' ',title)-1)),
			' ',
			upper(trim(substring(title, locate(' ',title)+1,1))),
			lower(substring(title, locate(' ',title)+2))
        );
set sql_safe_updates=1;

-- check for duplicates in the title column

select title, count(*) as duplicates
from film_copy
group by title
having count(*)>1;

-- no duplicate

-- the clean film table
select * from film_copy;

------ film actor--------------------
select * from film_actor;

--- film category---------------

select * from film_category;

---- inventory--------------
select * from inventory;

----- language----------------
select * from language;

--- payment------------------
select * from payment;

---- rental------------------
select * from rental;

---- staff-----------------------
select * from staff;

-- create a copy

create table staff_copy
like staff;

insert into staff_copy
select* from staff;

-- drop password and picture columns for ethical reason

alter table staff_copy
drop column picture;

alter table staff_copy
drop column password;

-- the clean staff table
select* from staff_copy;


-------------- store------------------------

select * from store;

------------- performing join----------------------

-- create a temp table by joining the actor and film actor table and then join
-- the resulting table with film

create temporary table combined_table as 
select ac.actor_id,ac.first_name,ac.last_name, fa.film_id,fa.last_update from actor_copy as ac
join film_actor as fa
 on ac.actor_id = fa.actor_id;
 
select* from combined_table;

create temporary table newCombined
select ct.actor_id, ct.first_name, ct.last_name, ct.film_id, f.title,f.release_year,f.language_id,
f.rental_duration,f.rental_rate,f.length,f.replacement_cost,f.rating,f.last_update 
from combined_table as ct
join film_copy as f
 on ct.film_id=f.film_id;
 
 select * from newCombined;
 
 
 -- create a similar combine table for the address,city and country
 
 create temporary table addressTable
 select ac.address_id,ac.house_number,ac.street,ac.district,ac.city_id,co.city,ac.postal_code,ac.phone,
 co.country_id,ac.last_update 
 from address_copy as ac
 join city_copy as co
	on ac.city_id= co.city_id;
    
select* from addressTable;

-- join the addressTable with country

select * 
from addressTable as at
right join country_copy as co
on at.country_id = co.country_id;




