create table customers(
	id int(11) unsigned not null auto_increment,
	firstname varchar(50) null,
	lastname varchar(50) null,
	email varchar(100) null,
	pass varchar(100) null,
	cc_customerid varchar(50) null,
	loggedin tinyint(1) null default 0,
	created_at timestamp null default now(),
	updated_at timestamp null default now(),
	deleted_at timestamp null default null,
	primary key(id),
	unique index email_UNIQUE (email ASC)
);

create table orders(
	id int(11) not null,
	customer_id int(11) null,
	product_id int(11) null,
	price int(11) null,
	purchase_date timestamp null default now(),
	created_at timestamp null default now(),
	updated_at timestamp null default now(),
	deleted_at timestamp null default null,
	primary key(id)
);

create table products(
	id int(11) not null auto_increment,
	image varchar(100) null,
	imgalt varchar(50) null,
	description text null,
	productname varchar(50) null,
	price float null,
	promotion float null,
	created_at timestamp null default now(),
	updated_at timestamp null default now(),
	deleted_at timestamp null default null,
	primary key(id)
);

insert into products (image, imgalt, price, promotion, productname, description)
values ('img/img-small/strings.png', 'string', 100, 0, 'Strings',
'A very authentic and beautiful instrument!!');