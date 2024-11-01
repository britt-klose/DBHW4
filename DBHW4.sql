-- DB Assignment 4
-- Brittany Klose
-- 10/22/24
use DBHW4;

-- --------------------------------------------------
-- 						Tables:
-- ---------------------------------------------------

CREATE TABLE IF NOT EXISTS actor (
    actor_id INT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL
);
-- ---------------------------------------------------

create table if not exists country(
	country_id int primary key,
    country varchar(100)
);
-- ---------------------------------------------------

create table if not exists city(
	city_id int primary key,
    city varchar(100),
    country_id int not null, -- FK
    foreign key (country_id) references country(country_id)
);
-- ---------------------------------------------------
create table if not exists address(
	address_id int primary key, 
    city_id int not null, -- FK
    
	address varchar(100), 
	address2 varchar(100), 
	district varchar(100), 
	postal_code varchar(200),
	phone varchar(200),

	foreign key (city_id) references city(city_id)
);
-- ---------------------------------------------------
create table if not exists category(
	category_id int primary key, 
    name varchar(100),
    
    constraint category_constraint check (name in 
		('Animation', 'Comedy', 'Family', 'Foreign', 'Sci-Fi', 'Travel', 'Children', 
        'Drama', 'Horror', 'Action', 'Classics', 'Games', 'New', 'Documentary', 'Sports', 'Music'))
);
-- ---------------------------------------------------
create table if not exists store(
	store_id int primary key,
    address_id int not null, -- FK
    
    foreign key(address_id) references address(address_id)
);
-- ---------------------------------------------------

create table if not exists customer(
	customer_id int primary key, 
	store_id int not null, -- FK
	first_name varchar(100),
	last_name varchar(100),
    email varchar(100),
    address_id int not null, -- FK
    active int,
    
    foreign key (store_id) references store(store_id),
    foreign key (address_id) references address(address_id),
    
    constraint active_status check (
		active in
        (0,1)
    ));
-- ---------------------------------------------------
create table if not exists language(
	language_id int primary key,
    name varchar(100)
);
-- ---------------------------------------------------
create table if not exists film(
	film_id int primary key, 
    title varchar(100),
    desription varchar(200),
    release_year year,
    language_id int not null, -- FK
    
    rental_duration int,
    rental_rate decimal, 
    length int, 
    replacement_cost decimal,
    rating varchar(100),
    special_features varchar(100),
    
    foreign key (language_id) references language(language_id),
    
    constraint features_constraint check (special_features in 
		('Behind the Scenes', 'Commentarie', 'Deleted Scenes', 'Trailers')),
        
	constraint rating_constraint check (rating in 
		('PG', 'G', 'NC-17', 'PG-13', 'R')),
        
	constraint duration_constraint check (rental_duration between 2 and 8),
    
	constraint rentrate_constraint check (rental_rate between 0.99 and 6.99),
    
    constraint replacement_constraint check (replacement_cost between 5.00 and 100.00),
    
	constraint length_constraint check (length between 30 and 200)
);
-- ---------------------------------------------------
create table if not exists film_actor(
	actor_id int not null, -- [PK, FK]
    film_id int not null, -- [PK, FK]
    
    primary key(actor_id, film_id),
    foreign key (actor_id) references actor(actor_id),
    foreign key (film_id) references film(film_id)
);
-- ---------------------------------------------------
create table if not exists staff(
	staff_id int primary key,
    address_id int not null, -- FK
    store_id int not null, -- FK
    
    first_name varchar(100),
	last_name varchar(100),
    email varchar(100),
    active int,
    username varchar(100),
    password varchar(100),
    
	foreign key (address_id) references address(address_id),
	foreign key (store_id) references store(store_id)
    
);
-- ---------------------------------------------------
create table if not exists inventory(
	inventory_id int primary key,
    film_id int not null, -- FK
    store_id int not null, -- FK
    
    foreign key (film_id) references film(film_id),
    foreign key (store_id) references store(store_id)
);
-- ---------------------------------------------------
create table if not exists rental(
	rental_id int primary key,
    rental_date datetime unique key, 
    inventory_id int not null,-- [UK, FK]
    customer_id int not null, -- [UK, FK]
    return_date datetime,
    staff_id int not null,
    unique key(inventory_id, customer_id),
    
    foreign key(inventory_id) references inventory(inventory_id),
    foreign key (customer_id) references customer(customer_id),
    foreign key (staff_id) references staff(staff_id)
);
-- ---------------------------------------------------
create table if not exists film_category(
	film_id int not null, -- [PK, FK]
    category_id int not null,  -- [PK, FK]

    primary key (film_id, category_id),
    foreign key (film_id) references film(film_id),
    foreign key (category_id) references category (category_id)
);
-- ---------------------------------------------------
create table if not exists payment(
	payment_id int primary key,
    customer_id int not null, -- FK
    staff_id int not null, -- FK
    rental_id int not null, -- FK
    amount decimal,
    payment_date datetime,
    
    constraint amount_constraint check (amount >= 0),
	foreign key (customer_id) references customer(customer_id),
	foreign key (staff_id) references staff(staff_id),
	foreign key (rental_id) references rental(rental_id)
    
);

-- ---------------------------------------------------------------
-- Querie 1: What is the average length of films in each 
-- category? List the results in alphabetic order of categories.
-- ---------------------------------------------------------------
select c.name as Category, format(avg(f.length),2) as AvgMin
from category c 
join film_category fc using (category_id)
join film f using (film_id)
group by c.name
order by c.name asc;


-- -------------------------------------------------------------------------------
-- Querie 2: Which categories have the longest and shortest average film lengths?
-- -------------------------------------------------------------------------------

select category.name as Category, format(avg(film.length),2) as AvgMin
from category 
join film_category using (category_id)
join film using (film_id)
group by category.name
having format(avg(film.length),2) >= all
	(
     select format(avg(film.length),2)
     from category 
     join film_category using (category_id)
	 join film using (film_id)
     where category.name=category.name
     group by category.name
    )
    
or format(avg(film.length),2) <= all
	(
     select format(avg(film.length),2) 
	 from category
	 join film_category using (category_id)
	 join film using (film_id)
     group by category.name
	)
order by format(avg(film.length),2) desc;
    
-- Side query for me to double check results above
select c.name as Category, format(avg(f.length),2) as AvgMin
from category c 
join film_category fc using (category_id)
join film f using (film_id)
group by c.name
order by format(avg(f.length),2) desc; 
    

-- -------------------------------------------------------------------------------
-- Querie 3: Which customers have rented action but not comedy or classic movies?
-- 		Note: Need to join customer, rental, category, film_cat, inventory 
-- -------------------------------------------------------------------------------
-- My version of mysql doesn't support Except so using 'Not Exists'
select 
	distinct concat(c.first_name, ' ', c.last_name) as 'Customer'
from customer c
	inner join rental r on c.customer_id=r.customer_id
    inner join inventory i on r.inventory_id=i.inventory_id
    inner join film_category fc on i.film_id=fc.film_id
    inner join category cat on fc.category_id=cat.category_id
    where cat.name='Action'
    and not exists(
		select *
        from customer c2
        	inner join rental r2 on c2.customer_id=r2.customer_id
			inner join inventory i2 on r2.inventory_id=i2.inventory_id
			inner join film_category fc2 on i2.film_id=fc2.film_id
			inner join category cat2 on fc2.category_id=cat2.category_id
            where r2.customer_id=c.customer_id
            and (cat2.name= 'Comedy' or cat2.name= 'Classics')
		)
	group by concat(c.first_name, ' ', c.last_name)
    order by concat(c.first_name, ' ', c.last_name) asc;
    
-- Side query to cheaply check results by seeing what categories customers have rented from. 
select 
	concat(c.first_name, ' ', c.last_name) as 'Customer', 
    group_concat(distinct cat.name order by cat.name asc separator ',  ' ) as 'Rented Categories'
from customer c
	inner join rental r on c.customer_id=r.customer_id
    inner join inventory i on r.inventory_id=i.inventory_id
    inner join film_category fc on i.film_id=fc.film_id
    inner join category cat on fc.category_id=cat.category_id
    inner join film f on fc.film_id=f.film_id
group by concat(c.first_name, ' ', c.last_name)
order by concat(c.first_name, ' ', c.last_name) asc;

-- Same answer as first query but I found a way to merge the previous 2 
-- queries so the results include the rented categories column. 
-- This version uses 'Have in set' instead of  where cat.name='Action' so 
-- that all other categories are included in the results with Action after filtering out comedy and classics

select 
	concat(c.first_name, ' ', c.last_name) as 'Customer', 
    group_concat(distinct cat.name order by cat.name asc separator ',  ' ) as 'Rented Categories'
from customer c
	inner join rental r on c.customer_id=r.customer_id
    inner join inventory i on r.inventory_id=i.inventory_id
    inner join film_category fc on i.film_id=fc.film_id
    inner join category cat on fc.category_id=cat.category_id
where 
    c.customer_id not in (
        select r2.customer_id
        from rental r2
		inner join inventory i2 on r2.inventory_id=i2.inventory_id
		inner join film_category fc2 on i2.film_id=fc2.film_id
		inner join category cat2 on fc2.category_id=cat2.category_id
        where cat2.name in ('Comedy', 'Classics')
    )
group by
    c.customer_id
having
    find_in_set('Action', (select group_concat(distinct cat2.name order by cat2.name asc separator ', ')
          from rental r3
          inner join inventory i3 on r3.inventory_id = i3.inventory_id
          inner join film_category fc3 on i3.film_id = fc3.film_id
		  inner join category cat2 on fc3.category_id = cat2.category_id
          where r3.customer_id = c.customer_id)) > 0
order by concat(c.first_name, ' ', c.last_name) asc;



-- -------------------------------------------------------------------------
-- Querie 4: Which actor has appeared in the most English-language movies?
-- -------------------------------------------------------------------------

-- --------------------
-- Using Limit
-- -------------------
select concat(a.first_name, ' ', a.last_name) as 'Actor', count(f.film_id) as 'Film Count'
from actor a
	inner join film_actor fa on a.actor_id=fa.actor_id
    inner join film f on fa.film_id=f.film_id
    inner join language l on f.language_id=l.language_id
where l.name='English'
group by a.first_name, ' ', a.last_name
order by count(f.film_id) desc
 limit 1; 


-- --------- ------------
-- Using having()>=all
-- ---------------------
select concat(a.first_name, ' ', a.last_name) as 'Actor', count(f.film_id) as 'Film Count'
from actor a
	inner join film_actor fa on a.actor_id=fa.actor_id
    inner join film f on fa.film_id=f.film_id
    inner join language l on f.language_id=l.language_id
where l.name='English'
group by a.first_name, ' ', a.last_name
having count(f.film_id) >= all(
	select count(f.film_id)
    from actor a
    inner join film_actor fa on a.actor_id=fa.actor_id
    inner join film f on fa.film_id=f.film_id
    inner join language l on f.language_id=l.language_id
    group by a.first_name, ' ', a.last_name
);	

-- -------------------------------------------------------------
-- Querie 5: How many distinct movies were rented for exactly 
-- 10 days from the store where Mike works?
-- --------------------------------------------------------------
-- Using Rental Duration
select count(distinct film.title) as FilmCount
from film 
	inner join inventory on film.film_id=inventory.film_id
	inner join store on inventory.store_id=store.store_id
	inner join staff on store.store_id=staff.store_id
where staff.first_name = 'Mike' and film.rental_duration=10;

-- Side query using return data and rental date to double check results 
select count(distinct film.title) as FilmCount
from film 
	inner join inventory on film.film_id=inventory.film_id
	inner join store on inventory.store_id=store.store_id
	inner join staff on store.store_id=staff.store_id
    inner join rental on inventory.inventory_id=rental.inventory_id
where staff.first_name = 'Mike' and rental.return_date - rental.rental_date=10;

-- Side query to check all disinct rental durations from the DB
select distinct rental_duration
from film
order by rental_duration asc;

-- ---------------------------------------------------------------
-- Querie 6: Alphabetically list actors who appeared in the movie 
-- with the largest cast of actors.
-- ----------------------------------------------------------------

-- -------------------------------------------------------
-- 				V1 Using Where Subquery:
-- -------------------------------------------------------
select
	concat (a.first_name, ' ', a.last_name) as Actors
from film f
inner join film_actor fa ON f.film_id = fa.film_id
inner join actor a on fa.actor_id = a.actor_id
where
    f.film_id = (
        select f.film_id
        from film f
        inner join film_actor fa on f.film_id = fa.film_id
        inner join actor a on fa.actor_id = a.actor_id
        group by f.film_id
        order by count(distinct a.actor_id) desc
        limit 1
    )
order by a.first_name, ' ', a.last_name desc;


-- -------------------------------------------------------
-- 				  V2 Using Group_Concat:
-- -------------------------------------------------------
-- includes film title, cast count, and full cast names
select 
	f.title, 
    count(distinct a.actor_id), 
    group_concat(a.first_name, ' ' , a.last_name order by a.first_name separator ',  ' ) as 'Cast'
from film f
	inner join film_actor fa on f.film_id = fa.film_id
    inner join actor a on fa.actor_id = a.actor_id
group by f.title
order by count(distinct a.actor_id) desc
limit 1;
    
-- Query to double check Lamba Cinciantii has the greatest cast count   
select 
	f.title, 
    count(distinct a.actor_id)
from film f
	inner join film_actor fa on f.film_id = fa.film_id
    inner join actor a on fa.actor_id = a.actor_id
group by f.title
order by count(distinct a.actor_id) desc;




 
