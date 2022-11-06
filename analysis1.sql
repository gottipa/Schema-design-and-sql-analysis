/*to get the latest and the last payment*/
select min(payment_date) as min_payment,
max(payment_date) as max_payment
 from payment;

/*to get the film time and the revenue it made*/
select film.title,sum(payment.amount) from payment join 
rental on 
payment.rental_id=rental.rental_id join inventory on
inventory.inventory_id = rental.inventory_id join 
film on film.film_id = inventory.film_id group by 
film.title order by 2 desc;

/*create tables to analyse the data using sql and design the schema*/
create table if not exists dimcustomer
(
customer_key serial primary key,
customer_id smallint not null,
first_name varchar(45) not null,
email varchar(50),
address varchar(50) not null,
address2 varchar(50),
district varchar(20) not null,
city varchar(50) not null,
country varchar(50) not null,
postal_code varchar(10),
phone varchar(20) not null,
active smallint not null,
create_date timestamp not null,
start_date date not null,
end_date date not null
);


create table if not exists dimmovie
(
movie_key serial primary key,
film_id smallint not null,
title varchar(225) not null,
description text,
release_year year,
language varchar(20) not null,
original_language varchar(20) not null,
rental_duration smallint not null,
length smallint not null,
rating varchar(5) not null,
special_features varchar(60) not null
);

create table if not exists dimstore
(
store_key serial primary key,
store_id smallint not null,
address varchar(50) not null,
address2 varchar(50),
district varchar(20) not null,
city varchar(50) not null,
country varchar(50) not null,
postal_code varchar(10),
manager_first_name varchar(45) not null,
manager_last_name varchar(45) not null,
start_date date not null,
end_date date not null
);

create table if not exists dimdate(
datekey integer not null primary key,
date date not null,
year smallint not null,
quarter smallint not null,
month smallint not null,
day smallint not null,
week smallint not null,
is_weekend boolean	
);

insert into dimdate
(datekey,date,year,quarter,month,day,week,is_weekend)
select
distinct(TO_CHAR(payment_date::DATE,'yyyyMMDD')::integer) as date_key,
date(payment_date) as date,
extract(year from payment_date) as year,
extract(quarter from payment_date) as quarter,
extract(month from payment_date) as month,
extract(day from payment_date) as day,
extract(week from payment_date) as week,
case when extract(ISODOW from payment_date) in (6,7) then true else false end as is_weekend
from payment;

insert into dimcustomer(customer_key,customer_id,first_name,
email,address,address2,district,city,country,postal_code,
phone,active,create_date,start_date,end_date)
select c.customer_id as customer_key,
c.customer_id,c.first_name,c.last_name,
c.email,a.address,a.address2,ci.city,co.country,a.postal_code,
a.phone,c.active,c.create_date,now() as start_date,
now() as end_date
from customer c
join address a on (c.address_id=a.address_id)
join city ci on (a.city_id=ci.city_id)
join country co on (ci.country_id = co.country_id);


insert into dimmovie(movie_key,film_id,title,description,
release_year,language,original_language,rental_duration,
length,rating,special_features)
select f.film_id as movie_key,
f.film_id,f.title,f.description,f.release_year,l.name,l.name,
f.rental_duration,
f.length,f.rating,f.special_features
from film f
join language l on (f.language_id=l.language_id);

insert into dimstore(store_key,store_id,address,address2,
district,city,country,postal_code,manager_first_name,
manager_last_name,start_date,end_date)
select 
s.store_id as store_key,
s.store_id,a.address,a.address2,a.district,c.city,co.country,
a.postal_code,st.first_name,st.last_name,
now() as start_date,now()as end_date
from store s join address a ON(s.address_id=a.address_id) join city c ON
(a.city_id=c.city_id) join country co ON
(c.country_id=co.country_id) join staff st ON
(s.address_id=st.address_id);
 
create table if not exists factsales(
sales_key serial primary key,
date_key integer references dimdate (datekey),
customer_key integer references dimcustomer (customer_key),
movie_key integer references dimmovie (movie_key),
store_key integer references dimstore (store_key),
sales_amount numeric
);



insert into factsales(date_key,customer_key,movie_key,store_key,sales_amount)
select 
TO_CHAR(payment_date::DATE,'yyyMMDD')::integer as date_key,
p.customer_id as customer_key,
i.film_id as movie_key,
i.store_id as store_key,
p.amount as sales_amount
from payment p
join rental r on (p.rental_id=r.rental_id)
join inventory i on (r.inventory_id=i.inventory_id)
;