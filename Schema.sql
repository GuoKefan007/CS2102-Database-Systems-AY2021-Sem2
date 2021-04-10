drop table if exists sessions, rooms, customers, course_packages, credit_cards, buys, employees, pay_slips, 
full_time_emp, part_time_emp, instructors, full_time_instructors, part_time_instructors, administrators, managers, course_areas, 
specializes, courses, offerings, redeems, registers, owns cascade;

create table employees (
    eid         integer primary key,
    name        text,
    address     text,
    email       text,
    phone       text,
    join_date   date,
    depart_date date,
    check(join_date <  depart_date)
);

create table part_time_emp(
	eid INTEGER primary key references employees
        on delete cascade
        on update cascade,
  	hourly_rate integer check (hourly_rate > 0)
);

create table full_time_emp(
	monthly_salary integer check (monthly_salary > 0),
  	eid integer primary key references employees
  		on delete cascade
        on update cascade
);

create table instructors(
	eid integer primary key references employees
  		on delete cascade
        on update cascade
);

create table part_time_instructors(
	eid integer primary key references part_time_emp
  		on delete cascade
        on update cascade
);

create table full_time_instructors(
	eid integer primary key references full_time_emp
  		on delete cascade
        on update cascade
);

create table administrators (
	eid integer primary key references full_time_emp
  		on delete cascade
        on update cascade
);

create table managers(
	eid integer primary key references full_time_emp 
  		on delete cascade
        on update cascade
);

create table course_areas(
	name varchar(50) primary key,
  	Manager_eid integer references managers(eid)
);

create table specializes (
	eid integer references instructors 
  		on delete cascade
        on update cascade,
  	name text references course_areas 
  		on delete cascade
        on update cascade,
  	primary key (eid, name)
);

create table pay_slips (
	payment_date date,
  	amount integer not null check (amount >= 0),
  	num_work_hours integer not null check (num_work_hours >= 0),
  	num_work_days integer not null check (num_work_days >= 0 and num_work_days <= 31),
  	eid integer references employees 
  		on delete cascade
		on update cascade,
  	primary key (eid, payment_date)
);

-- CS2102 Project Schema (middle part)

CREATE TABLE courses (
    course_id        integer primary key,
    title            varchar(50) unique,
    description      text,
    duration         integer,   -- in hours
    area             varchar(50) not null,
    foreign key (area) references course_areas(name)
);

CREATE TABLE offerings (
    course_id                     integer,
    launch_date                   date,
    -- determined by the earliest time of sessions
    start_date                    date, 
    end_date                      date,
    fees                          float,
    registration_deadline         date
        check (start_date - registration_deadline >= 10),
    target_number_registrations   integer,
    seating_capacity              integer, -- sum of capacities of sessions
    administrator                 integer not null,
    primary key (course_id, launch_date),
    foreign key (administrator) references employees(eid), 
    foreign key (course_id) references courses(course_id)
);

CREATE TABLE course_packages (
    package_id              text primary key,
    name                    text,
    sale_start_date         date,
    sale_end_date           date,
    num_free_registrations  integer,
    price                   float，
    check(sale_start_date < sale_end_date),
    check(price >= 0)
);

create table rooms (
    rid                 integer primary key,
    location            text,
    seating_capacity    integer
);

CREATE TABLE sessions (
    sid              integer,
    launch_date      date not null,
    course_id        integer not null,
    date             date,
    start_time       integer,
    end_time         integer,
    rid              integer not null,
    seating_capacity integer not null, 
    instructor       integer not null,
    primary key (sid, course_id, launch_date),
    foreign key (launch_date, course_id) references offerings(launch_date, course_id)
            on delete cascade 
            on update cascade,
    foreign key (rid) references rooms(rid),
    foreign key (instructor) references instructors(eid),
    check (((start_time >= 9 and end_time <= 12) or (start_time >= 14 and end_time <= 18))
    and (start_time >= 0 and start_time <= 24 and end_time >= 0 and end_time <= 24))
);

CREATE TABLE customers (
    cust_id integer primary key,
    name    text,
    address text,
    phone   text,
    email   text
    );						     
						     
CREATE TABLE credit_cards(
    cust_id integer references customers on delete cascade on update cascade,
    card_number text primary key,
    cvv integer,
    expiry_date date,
    from_date date
);

CREATE TABLE owns(
    cust_id integer not null references customers on delete cascade on update cascade,
    card_number text not null references credit_cards on delete cascade on update cascade,
    primary key (cust_id, card_number)
);

CREATE TABLE buys(
    cust_id integer references customers on delete cascade on update cascade,
    card_number text references credit_cards on delete cascade on update cascade,
    package_id integer references course_packages on delete cascade on update cascade,
    date date, -- buys_date
    num_remaining_redemptions integer not null check (num_remaining_redemptions >= 0),
    primary key (cust_id, card_number, package_id, date)
);

create table redeems(
	date date, -- when redeem, redeems_date
	sid integer, -- session id
	launch_date date, -- when session launches
	course_id integer, 
	buys_date date, -- when buy the course package
	card_number text, 
	package_id integer, -- package id owned by the customer, in Table buys
	cust_id integer,
	primary key (date, sid, launch_date, course_id, buys_date, package_id, card_number),
	foreign key (sid, course_id, launch_date) references sessions on update cascade on delete cascade,
	foreign key (package_id, card_number, buys_date, cust_id) references buys(package_id, card_number, date, cust_id) on update cascade on delete cascade
);
						     
create table registers(
	register_date date,
	card_number text not null,
	cust_id integer not null,
	sid integer not null,
	launch_date date not null,
	course_id integer not null,
	primary key (date, cust_id, card_number, sid, launch_date, course_id),
	foreign key (cust_id, card_number) references owns on delete cascade on update cascade,
	foreign key (sid, course_id, launch_date) references sessions on delete cascade on update cascade
);
						     					     
CREATE TABLE cancels (
    cancel_date date,
    cust_id integer,
    sid integer,
    launch_date date,
    course_id integer,
    refund_amt float,
    package_credit int,
    primary key (cancel_date, cust_id, sid, launch_date, course_id),
    foreign key (cust_id) references customers on delete cascade on update cascade,
    foreign key (sid, launch_date, course_id) references sessions (sid, launch_date, course_id) on delete cascade on update cascade
);
						     
				    
------------------Trigger--------------------------
						     						     
create or replace function owns_log_func() returns trigger
as $$
begin
insert into owns(cust_id, card_number)
values (new.cust_id, new.card_number);
return null;
end;
$$ language plpgsql;
						     
create trigger owns_log_trigger
after insert on credit_cards
for each row execute function owns_log_func();
						     
create or replace function pay_slips_func() returns trigger
as $$
begin
if (new.amount < 0) then
raise notice 'You cannot pay negative salary to your employees!';
return null;
elsif (new.amount > 100000) then
raise notice 'We cannot afford such a high salary!';
return null;
end if;
return new;
end;
$$ language plpgsql;

create trigger pay_slips_trigger
before insert on pay_slips
for each row execute function pay_slips_func();
						     
create or replace function if_full_not_part_check() returns trigger
as $$
begin
if (exists (select 1 from full_time_emp where eid = new.eid)) then
raise exception 'This employee is already a full-time employee.';
return null;
end if;
return new;
end;
$$ language plpgsql;

create or replace function if_part_not_full_check() returns trigger
as $$
begin
if (exists (select 1 from part_time_emp where eid = new.eid)) then
raise exception 'This employee is already a part-time employee.';
return null;
end if;
return new;
end;
$$ language plpgsql;

create trigger if_full_then_not_part_trigger
before insert on part_time_emp
for each row execute function if_full_not_part_check();

create trigger if_part_then_not_full_trigger
before insert on full_time_emp
for each row execute function if_part_not_full_check();

create or replace function role_check() returns trigger
as $$
begin
if (exists (select 1 from instructors where eid = new.eid)) then
raise exception 'This employee is already an instructor.';
return null;
end if;
if (exists (select 1 from administrators where eid = new.eid)) then
raise exception 'This employee is already an administrator.';
return null;
end if;
if (exists (select 1 from managers where eid = new.eid)) then
raise exception 'This employee is already a manager.';
return null;
end if;

return new;
end;
$$ language plpgsql;

create trigger is_only_instructor_trigger
before insert on instructors
for each row execute function role_check();

create trigger is_only_admin_trigger
before insert on administrators
for each row execute function role_check();

create trigger is_only_manager_trigger
before insert on managers
for each row execute function role_check();
