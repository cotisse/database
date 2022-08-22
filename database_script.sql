
create user cotisse with password 'cotisse';
CREATE DATABASE cotisse_db;
grant all privileges on database cotisse_db to cotisse;

create sequence users_seq;

create table users(
    id serial PRIMARY KEY,
    name VARCHAR(30),
    phone VARCHAR(10),
    password VARCHAR(100),
    email varchar(20)
);
-- insert into users (name,phone,password,email) values ('Mariano Randriamanjaka','0341913411','loveOfMyLife','mariano@gmail.com');
-- insert into users (name,phone,password,email) values ('tsiory Andria','0322276318','loveOfMyLife','tsiory@gmail.com');
-- insert into users (name,phone,password,email) values ('Anjara Ramananatsoa','0342435647','loveOfMyLife','anjara@gmail.com');
-- insert into users (name,phone,password,email) values ('Michael Randria','0331213432','loveOfMyLife','michael@gmail.com');
-- insert into users (name,phone,password,email) values ('Anjaratiana sauce','038567454','loveOfMyLife','sauce@gmail.com');

create table classe(
    id serial PRIMARY KEY,
    label VARCHAR(30),
    extra float
);
insert into classe(label,extra) values ('LITE',0);
insert into classe(label,extra) values ('PREMIUM',11000);
insert into classe(label,extra) values ('VIP',35000);

create table city(
    id serial PRIMARY KEY,
    label VARCHAR(50)
);
alter table city add column code VARCHAR(10);

insert into city(label,code) values ('Antananarivo','TNR');
insert into city(label,code) values ('Toamasina','TMT');
insert into city(label,code) values ('Mahajanga','MJG');
insert into city(label,code) values ('Tulear','TLR');
insert into city(label,code) values ('Antsiranana','ATR');
insert into city(label,code) values ('Fianarantsoa','FNR');

create table brand(
    id serial PRIMARY KEY,
    label VARCHAR(50)
);
insert into brand (label) values ('Mercedes-Benz');
insert into brand (label) values ('Wolkswagen');
insert into brand (label) values ('Renault');
create table destination(
    id serial PRIMARY KEY,
    depart int,
    arrival int,
    price float,
    CONSTRAINT fk_dtrip_city FOREIGN KEY (depart) references city(id),
    CONSTRAINT fk_atrip_city FOREIGN KEY (depart) references city(id)
);
insert into destination (depart,arrival,price) values(1,2,25000);
insert into destination (depart,arrival,price) values(3,1,40000);
insert into destination (depart,arrival,price) values(6,1,25000);
create table vehicle(
    id serial PRIMARY KEY,
    id_brand int,
    id_classe int,
    place_number int,
    registration VARCHAR(15),
    description varchar(50),
    CONSTRAINT fk_vehicle_brand FOREIGN KEY(id_brand) references brand(id),
    CONSTRAINT fk_vehicle_classe FOREIGN KEY(id_classe) references classe(id)
);
insert into vehicle(id_brand,id_classe,place_number,registration) values (1,1,27,'1345 TAF');

create table place(
    id serial PRIMARY KEY,
    number int,
    int_state int,
    label_state varchar(15),
    id_vehicle int,
    CONSTRAINT fk_place_vehicle FOREIGN KEY (id_vehicle) references vehicle(id)
);



create table trip(
    id serial PRIMARY KEY,
    departure_date TIMESTAMP,
    id_vehicle int,
    id_destination int,
    CONSTRAINT fk_trip_vehicle FOREIGN KEY(id_vehicle) references vehicle(id),
    CONSTRAINT fk_trip_destination FOREIGN KEY(id_destination) references destination(id)
);
insert into trip(departure_date,id_vehicle,id_destination) values ('2020-01-31 08:00:00',1,1);
create table reservation(
    id serial PRIMARY KEY,
    id_users int,
    date TIMESTAMP,
    id_trip int,
    id_place int,
    CONSTRAINT fk_reservation_users FOREIGN KEY(id_users) references users(id),
    CONSTRAINT fk_reservation_trip  FOREIGN KEY(id_trip) references trip(id),
    CONSTRAINT fk_reservation_place FOREIGN KEY (id_place) references place(id)
);

create table bill(
    id serial PRIMARY KEY,
    id_reservation int,
    total float,
    date TIMESTAMP,
    CONSTRAINT fk_bill_reservation FOREIGN KEY (id_reservation) references reservation(id)
);

create table bill_details(
    id serial PRIMARY KEY,
    id_bill int,
    label VARCHAR(30),
    amount float,
    CONSTRAINT fk_billd_bill FOREIGN KEY (id_bill) references bill(id)
);




create or replace view complete_vehicle as select vehicle.id,id_brand,id_classe,place_number,registration,description,brand.label as brand,classe.label as classe,extra from vehicle join brand on brand.id = vehicle.id_brand join classe on classe.id = vehicle.id_classe;
create view destination_part1 as select destination.id,depart,arrival,price,label as depart_city,code as depart_code from destination join city on city.id = destination.depart;
create view complete_destination as select destination_part1.id,depart,arrival,price,depart_city,depart_code,label as arrival_city,code as arrival_code from destination_part1 join city on city.id = destination_part1.arrival;

-- ANDROANY
create view trip_part1 as select trip.id,departure_date,id_vehicle,id_destination,depart,arrival,price,depart_city,depart_code,arrival_city,arrival_code from trip join complete_destination on trip.id_destination = complete_destination.id ;
create view complete_trip as select trip_part1.id,departure_date,id_vehicle,id_destination,depart,arrival,price,depart_city,depart_code,arrival_city,arrival_code,id_classe,place_number,registration,brand,classe,extra,price+extra as total from trip_part1 join complete_vehicle on trip_part1.id_vehicle = complete_vehicle.id;

create view trip_places as select trip.id as id_trip, place.id as id_place ,trip.id_vehicle,number,int_state,label_state from trip join place on place.id_vehicle = trip.id_vehicle;
insert into reservation(id_users,date,id_trip,id_place)values(15,now(),2,1);

-- create view reserved places

create OR REPLACE view reserved_places as select reservation.id_trip,reservation.id_place,id_vehicle,number,int_state,label_state,0 etat from reservation,trip_places where (reservation.id_trip,reservation.id_place) = (trip_places.id_trip, trip_places.id_place);

create OR REPLACE view free_places as select *,1 etat from trip_places where (id_trip,id_place) not in (select id_trip,id_place from reserved_places);

create OR replace view places_state as (select * from reserved_places) UNION (select * from free_places) order by number;
create view place_final as select rownum AS ID,* from places_state;
-- create view trip_essential as select id,departure_date,depart,arrival,depart_city,depart_code,arrival_city,arrival_code,id_classe,classe,total from complete_trip;
create or replace view trip_essential as select id,departure_date,depart,arrival,depart_city,depart_code,arrival_city,arrival_code,id_classe,classe,total,(select count(*) from places_state where id_trip = id and etat = 1) as libre from complete_trip;



-- 12 fev:
alter table reservation add column etat int;
update reservation set etat = 1;
drop view complete_reservation;
create view complete_reservation as select reservation.id,id_users,date,id_trip,id_place,departure_date,depart_city,depart_code,arrival_city,arrival_code,classe,total,libre,number,etat from reservation join trip_essential on id_trip = trip_essential.id join place on place.id=id_place;


-- data for online
-- insert into trip values(1,'2020-02-15 05:00:00',33,1);
-- insert into trip values(2,'2020-02-15 05:00:00',34,1);
-- insert into trip values(3,'2020-02-15 05:00:00',35,1);
-- insert into trip values(13,'2020-02-15 05:30:00',41,1);
-- insert into trip values(4,'2020-02-15 12:00:00',36,1);
-- insert into trip values(5,'2020-02-15 12:00:00',37,1);
-- insert into trip values(6,'2020-02-15 12:00:00',38,1);
-- insert into trip values(7,'2020-02-15 21:00:00',39,1);
-- insert into trip values(8,'2020-02-15 21:00:00',40,1);
-- insert into trip values(9,'2020-02-15 21:00:00',41,1);

-- insert into trip values(14,'2020-02-18 05:00:00',33,1);
-- insert into trip values(15,'2020-02-18 05:00:00',34,1);
-- insert into trip values(16,'2020-02-18 05:00:00',35,1);
-- insert into trip values(23,'2020-02-18 05:30:00',41,1);
-- insert into trip values(24,'2020-02-18 12:00:00',36,1);
-- insert into trip values(18,'2020-02-18 12:00:00',37,1);
-- insert into trip values(19,'2020-02-18 12:00:00',38,1);
-- insert into trip values(20,'2020-02-18 21:00:00',39,1);
-- insert into trip values(21,'2020-02-18 21:00:00',40,1);
-- insert into trip values(22,'2020-02-18 21:00:00',41,1);

-- insert into trip values(10,'2020-02-15 02:00:00',33,4);
-- insert into trip values(11,'2020-02-15 02:00:00',34,4);
-- insert into trip values(12,'2020-02-15 02:00:00',35,4);
