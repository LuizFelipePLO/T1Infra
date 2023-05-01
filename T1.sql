-- T1 Infraestrutura de Dados 
-- Luiz Felipe Porto Lara de Oliveira
-- Mátricula: 20103391

-- Tamanho das tabelas acessíveis ao usuário em datablocks
SELECT table_name, num_rows, avg_row_len, blocks, blocks*8 AS size_in_kb
FROM user_tables
ORDER BY table_name ASC;

-- Tamanho das tabelas em datablocks
SELECT table_name, num_rows, avg_row_len, blocks, blocks*8 AS size_in_kb
FROM all_tables
WHERE owner='ARRUDA'
ORDER BY table_name ASC;

-- Etapa 1
-- Criar tabelas
SELECT
'create table ' || table_name || ' as select * from arruda.' || table_name || ';'
FROM
all_tables
WHERE owner = 'ARRUDA'
AND table_name LIKE 'AIR_%';

CREATE TABLE AIR_AIRLINES as SELECT * from arruda.AIR_AIRLINES;
CREATE TABLE AIR_AIRPLANES as SELECT * from arruda.AIR_AIRPLANES;
CREATE TABLE AIR_AIRPLANE_TYPES as SELECT * from arruda.AIR_AIRPLANE_TYPES;
CREATE TABLE AIR_AIRPORTS as SELECT * from arruda.AIR_AIRPORTS;
CREATE TABLE AIR_AIRPORTS_GEO as SELECT * from arruda.AIR_AIRPORTS_GEO;
CREATE TABLE AIR_BOOKINGS as SELECT * from arruda.AIR_BOOKINGS;
CREATE TABLE AIR_FLIGHTS as SELECT * from arruda.AIR_FLIGHTS;
CREATE TABLE AIR_FLIGHTS_SCHEDULES as SELECT * from arruda.AIR_FLIGHTS_SCHEDULES;
CREATE TABLE AIR_PASSENGERS as SELECT * from arruda.AIR_PASSENGERS;
CREATE TABLE AIR_PASSENGERS_DETAILS as SELECT * from arruda.AIR_PASSENGERS_DETAILS;

-- Selects
SELECT * from air_airlines;
SELECT * from air_airplane_types;
SELECT * from air_airplanes;
SELECT * from air_airports;
SELECT * from air_airports_geo;
SELECT * from air_bookings;
SELECT * from air_flights; 
SELECT * from air_flights_schedules;
SELECT * from air_passengers; 
SELECT * from air_passengers_details;

-- Drops
DROP TABLE air_airlines CASCADE CONSTRAINTS;
DROP TABLE air_airplane_types CASCADE CONSTRAINTS;
DROP TABLE air_airplanes CASCADE CONSTRAINTS;
DROP TABLE air_airports CASCADE CONSTRAINTS;
DROP TABLE air_airports_geo CASCADE CONSTRAINTS;
DROP TABLE air_bookings CASCADE CONSTRAINTS;
DROP TABLE air_flights CASCADE CONSTRAINTS;
DROP TABLE air_flights_schedules CASCADE CONSTRAINTS;
DROP TABLE air_passengers CASCADE CONSTRAINTS;
DROP TABLE air_passengers_details CASCADE CONSTRAINTS;

DROP CLUSTER cl_passageiros;
DROP CLUSTER cl_aeroportos;
DROP CLUSTER cl_aeronaves;
DROP CLUSTER cl_voos;

-- Describes
describe arruda.air_airlines;
describe arruda.air_airplane_types;
describe arruda.air_airplanes;
describe arruda.air_airports;
describe arruda.air_airports_geo;
describe arruda.air_bookings;
describe arruda.air_flights;
describe arruda.air_flights_schedules;
describe arruda.air_passengers;
describe arruda.air_passengers_details;

-- Etapa 2
-- Listar o nome completo (primeiro nome + último nome), a idade e a cidade de todos os passageiros do sexo feminino (sex='w')
-- com mais de 40 anos, residentes no país 'BRAZIL'. [resposta sugerida = 141 linhas]
SELECT 
CONCAT(CONCAT(P.firstname,' '), P.lastname) AS Nome,
TRUNC(months_between(sysdate,PD.birthdate)/12) AS Idade,
PD.city AS Cidade
FROM air_passengers_details PD
INNER JOIN air_passengers P ON P.passenger_id = PD.passenger_id
WHERE PD.country = 'BRAZIL'
AND PD.birthdate <= ADD_MONTHS(SYSDATE,-480)
AND PD.sex = 'w';



-- Listar o nome da companhia aérea, o identificador da aeronave, o nome do tipo de aeronave e o número de todos os voos operados por essa companhia aérea (independentemente de a aeronave
-- ser de sua propriedade) que saem E chegam em aeroportos localizados no país 'BRAZIL'. [resposta sugerida = 8 linhas - valor corrigido]    
SELECT 
AL.airline_name AS "Nome da companhia",
AF.flightno AS "Número do voo",
AP.airplane_id AS "Id. da Aeronave",
APT.name AS "Tipo da aeronave"
FROM air_flights AF
INNER JOIN air_airplanes AP ON AP.airplane_id = AF.airplane_id
INNER JOIN air_airplane_types APT ON APT.airplane_type_id = AP.airplane_type_id
INNER JOIN air_airports APOP ON APOP.airport_id = AF.from_airport_id
INNER JOIN air_airports APOC ON APOC.airport_id = AF.to_airport_id
INNER JOIN air_airports_geo APGP ON APGP.airport_id = APOP.airport_id
INNER JOIN air_airports_geo APGC ON APGC.airport_id = APOC.airport_id
INNER JOIN air_airlines AL ON AL.airline_id = AF.airline_id
WHERE APGP.country = 'BRAZIL' 
AND APGC.country = 'BRAZIL';

-- Listar o número do voo, o nome do aeroporto de saída e o nome do aeroporto de destino, o nome completo (primeiro e último nome) e o assento de cada passageiro, para todos os voos
-- que partem no dia do seu aniversário neste ano (caso a consulta não retorne nenhuma linha, faça para o dia subsequente até encontrar uma data que retorne alguma linha). 
--[resposta sugerida = 106 linhas para o dia 25/03/2023]        
SELECT
AF.flightno AS "Número do voo",
APOP.name AS "Aeroporto de saída",
APOC.name AS "Aeroporto de chegada",
CONCAT(CONCAT(P.firstname,' '), P.lastname) AS Nome, 
B.seat AS Assento,
AF.departure
FROM air_flights AF
INNER JOIN air_airports APOP ON APOP.airport_id = AF.from_airport_id
INNER JOIN air_airports APOC ON APOC.airport_id = AF.to_airport_id
INNER JOIN air_bookings B ON B.flight_id = AF.flight_id
INNER JOIN air_passengers P ON P.passenger_id = B.passenger_id
INNER JOIN air_passengers_details PD ON PD.passenger_id = P.passenger_id
WHERE EXTRACT(YEAR FROM AF.departure) = EXTRACT(YEAR FROM SYSDATE)
AND TO_CHAR(TRUNC(AF.departure), 'DD-MM') = '08-07';

-- Listar o nome da companhia aérea bem como a data e a hora de saída de todos os voos que chegam para a cidade de 'NEW YORK' que partem às terças, quartas ou quintas-feiras,
-- no mês do seu aniversário (caso a consulta não retorne nenhuma linha, faça para o mês subsequente até encontrar um mês que retorne alguma linha).
-- [resposta sugerida = 1 linha para o mês de março de 2023]
SELECT 
AL.airline_name AS Nome,
TO_CHAR(AF.departure, 'HH24:MI:SS') AS "Partida do voo",
TO_CHAR(AF.arrival, 'HH24:MI:SS') AS "Chegada do voo"
FROM air_flights AF
INNER JOIN air_flights_schedules AFS ON AFS.flightno = AF.flightno
INNER JOIN air_airports APOC ON APOC.airport_id = AF.to_airport_id
INNER JOIN air_airports_geo APGC ON APGC.airport_id = APOC.airport_id
INNER JOIN air_airlines AL ON AL.airline_id = AF.airline_id
WHERE APGC.city = 'NEW YORK'
AND (AFS.tuesday = 1 OR AFS.wednesday = 1 OR AFS.thursday = 1)
AND TO_CHAR(TRUNC(AF.departure), 'MM-YYYY') = '01-2023';

-- Crie uma consulta que seja resolvida adequadamente com um acesso hash em um cluster com pelo menos duas tabelas. 
-- A consulta deve utilizar todas as tabelas do cluster e pelo menos outra tabela fora dele.
SELECT 
APT.name AS "Tipo de aeronave",
AP.capacity AS "Capacidade máxima",
AL.airline_name AS "Empresa aérea"
FROM air_airplanes AP
INNER JOIN air_airplane_types APT ON APT.airplane_type_id = AP.airplane_type_id
INNER JOIN air_airlines AL ON AL.airline_id = AP.airline_id 
WHERE AL.airline_name = 'Brazil Airlines'
ORDER BY APT.name;

----------------------------------------------------------------------------------------------------------------------------
-- Selects (repetidos por praticidade)
SELECT * from air_airlines;
SELECT * from air_airplane_types;
SELECT * from air_airplanes;
SELECT * from air_airports;
SELECT * from air_airports_geo;
SELECT * from air_bookings;
SELECT * from air_flights; 
SELECT * from air_flights_schedules;
SELECT * from air_passengers; 
SELECT * from air_passengers_details;

-- Inicío da sincronização

-- Cluster por Hash
CREATE CLUSTER cl_aeronaves(
airplane_type_id number(3,0)
)
SIZE 8K
hashkeys 32;

CREATE CLUSTER cl_aeroportos(
    airport_id number(5,0)
)
SIZE 8K
hashkeys 256;

CREATE CLUSTER cl_voos(
flightno char(8)
)
SIZE 8K
hashkeys 32;

CREATE CLUSTER cl_passageiros(
passenger_id number(12,0)
)
SIZE 8K
hashkeys 1024;

-- Tabelas com clusters
CREATE TABLE air_passengers (
PASSENGER_ID NUMBER(12) NOT NULL,
PASSPORTNO CHAR(9) NOT NULL, 
FIRSTNAME VARCHAR2(100) NOT NULL,
LASTNAME VARCHAR2(100) NOT NULL  
)
CLUSTER cl_passageiros(passenger_id);

CREATE TABLE air_passengers_details (
PASSENGER_ID NUMBER(12) NOT NULL,
BIRTHDATE DATE NOT NULL,
SEX CHAR(1) NOT NULL,
STREET VARCHAR2(100),
CITY VARCHAR2(100) NOT NULL,
ZIP NUMBER(5) NOT NULL,
COUNTRY VARCHAR2(100),
EMAILADDRESS VARCHAR2(120),
TELEPHONENO VARCHAR2(30) 
)
CLUSTER cl_passageiros(passenger_id);

CREATE TABLE air_airports (
AIRPORT_ID NUMBER(5,0) NOT NULL,
IATA CHAR(3), 
ICAO CHAR(4) NOT NULL,
NAME VARCHAR2(50) NOT NULL 
)
CLUSTER cl_aeroportos(airport_id);

CREATE TABLE air_airports_geo (
AIRPORT_ID NUMBER(5,0) NOT NULL,
NAME VARCHAR2(50)NOT NULL,
CITY VARCHAR2(50),
COUNTRY VARCHAR2(50),
LATITUDE NUMBER(11,8) NOT NULL,
LONGITUDE NUMBER(11,8)NOT NULL
)
CLUSTER cl_aeroportos(airport_id);

CREATE TABLE air_airplanes (
AIRPLANE_ID NUMBER(5,0) NOT NULL,
AIRLINE_ID NUMBER(38) NOT NULL,
AIRPLANE_TYPE_ID NUMBER(3) NOT NULL,
CAPACITY NUMBER(3) NOT NULL 
)
CLUSTER cl_aeronaves(airplane_type_id);

CREATE TABLE air_airplane_types (
AIRPLANE_TYPE_ID NUMBER(3) NOT NULL, NAME VARCHAR2(50) NOT NULL 
)
CLUSTER cl_aeronaves(airplane_type_id);

CREATE TABLE air_flights (
FLIGHT_ID NUMBER(10) NOT NULL,
FLIGHTNO CHAR(8) NOT NULL,
AIRLINE_ID NUMBER(5) NOT NULL,
FROM_AIRPORT_ID NUMBER(5) NOT NULL,
TO_AIRPORT_ID NUMBER(5) NOT NULL,
AIRPLANE_ID NUMBER(5) NOT NULL,
DEPARTURE TIMESTAMP(6) NOT NULL,
ARRIVAL TIMESTAMP(6) NOT NULL
)
CLUSTER cl_voos(flightno);

CREATE TABLE air_flights_schedules (
FLIGHTNO CHAR(8) NOT NULL,
AIRLINE_ID NUMBER(5) NOT NULL,
FROM_AIRPORT_ID NUMBER(5) NOT NULL, 
TO_AIRPORT_ID NUMBER(5) NOT NULL, 
DEPARTURE DATE NOT NULL,
ARRIVAL DATE NOT NULL,
MONDAY NUMBER(1) NOT NULL,
TUESDAY NUMBER(1) NOT NULL,
WEDNESDAY NUMBER(1) NOT NULL, 
THURSDAY NUMBER(1) NOT NULL,
FRIDAY NUMBER(1) NOT NULL, 
SATURDAY NUMBER(1) NOT NULL,
SUNDAY NUMBER(1) NOT NULL 
)
CLUSTER cl_voos(flightno);

CREATE TABLE AIR_AIRLINES AS SELECT * FROM arruda.AIR_AIRLINES;
CREATE TABLE AIR_BOOKINGS AS SELECT * FROM arruda.AIR_BOOKINGS;

-- PKs
ALTER TABLE air_airlines
ADD CONSTRAINT pk_airlines PRIMARY KEY (airline_id);

ALTER TABLE air_airplane_types
ADD CONSTRAINT pk_airplane_types PRIMARY KEY (airplane_type_id);

ALTER TABLE air_airplanes
ADD CONSTRAINT pk_airplanes PRIMARY KEY (airplane_id);

ALTER TABLE air_airports
ADD CONSTRAINT pk_airports PRIMARY KEY (airport_id);

ALTER TABLE air_airports_geo
ADD CONSTRAINT pk_airports_geo PRIMARY KEY (airport_id);

ALTER TABLE air_bookings
ADD CONSTRAINT pk_bookings PRIMARY KEY (booking_id);

ALTER TABLE air_flights
ADD CONSTRAINT pk_flights PRIMARY KEY (flight_id);

ALTER TABLE air_flights_schedules
ADD CONSTRAINT pk_flights_schedules PRIMARY KEY (flightno);

ALTER TABLE air_passengers
ADD CONSTRAINT pk_passengers PRIMARY KEY (passenger_id);

ALTER TABLE air_passengers_details
ADD CONSTRAINT pk_passengers_details PRIMARY KEY (passenger_id);

-- Uniques
ALTER TABLE air_airlines
ADD CONSTRAINT un_al_iata UNIQUE (iata);

ALTER TABLE air_airports
ADD CONSTRAINT un_ap_iata UNIQUE (iata);

ALTER TABLE air_passengers
ADD CONSTRAINT un_p_passportno UNIQUE (passportno);

-- Inserts
INSERT INTO air_passengers
SELECT * FROM arruda.air_passengers;

INSERT INTO air_passengers_details
SELECT * FROM arruda.air_passengers_details;

INSERT INTO air_airports
SELECT * FROM arruda.air_airports;

INSERT INTO air_airports_geo
SELECT * FROM arruda.air_airports_geo;

INSERT INTO air_flights
SELECT * FROM arruda.air_flights;

INSERT INTO air_flights_schedules
SELECT * FROM arruda.air_flights_schedules;

INSERT INTO air_airplanes
SELECT * FROM arruda.air_airplanes;

INSERT INTO air_airplane_types
SELECT * FROM arruda.air_airplane_types;

-- FKs
ALTER TABLE air_airlines
ADD CONSTRAINT fk_airlines_base_airport_id
FOREIGN KEY (base_airport_id)
REFERENCES air_airports(airport_id);

ALTER TABLE air_airplanes
ADD CONSTRAINT fk_airplanes_airline_id
FOREIGN KEY (airline_id)
REFERENCES air_airlines(airline_id);

ALTER TABLE air_airplanes
ADD CONSTRAINT fk_airplanes_airplane_type_id
FOREIGN KEY (airplane_type_id)
REFERENCES air_airplane_types(airplane_type_id);

ALTER TABLE air_airports_geo
ADD CONSTRAINT fk_airports_geo_airport_id
FOREIGN KEY (airport_id)
REFERENCES air_airports(airport_id);

ALTER TABLE air_bookings
ADD CONSTRAINT fk_bookings_passenger_id
FOREIGN KEY (passenger_id)
REFERENCES air_passengers(passenger_id);

ALTER TABLE air_bookings
ADD CONSTRAINT fk_bookings_flight_id
FOREIGN KEY (flight_id)
REFERENCES air_flights(flight_id);

ALTER TABLE air_flights
ADD CONSTRAINT fk_flights_flightno
FOREIGN KEY (flightno)
REFERENCES air_flights_schedules(flightno);

ALTER TABLE air_flights
ADD CONSTRAINT fk_flights_airline_id
FOREIGN KEY (airline_id)
REFERENCES air_airlines(airline_id);

ALTER TABLE air_flights
ADD CONSTRAINT fk_flights_from_airport_id
FOREIGN KEY (from_airport_id)
REFERENCES air_airports(airport_id);

ALTER TABLE air_flights
ADD CONSTRAINT fk_flights_to_airport_id
FOREIGN KEY (to_airport_id)
REFERENCES air_airports(airport_id);

ALTER TABLE air_flights
ADD CONSTRAINT fk_flights_airplane_id
FOREIGN KEY (airplane_id)
REFERENCES air_airplanes(airplane_id);

ALTER TABLE air_flights_schedules
ADD CONSTRAINT fk_f_schedules_airline_id
FOREIGN KEY (airline_id)
REFERENCES air_airlines(airline_id);

ALTER TABLE air_flights_schedules
ADD CONSTRAINT fk_f_schedules_from_airport_id
FOREIGN KEY (from_airport_id)
REFERENCES air_airports(airport_id);

ALTER TABLE air_flights_schedules
ADD CONSTRAINT fk_f_schedules_to_airport_id
FOREIGN KEY (to_airport_id)
REFERENCES air_airports(airport_id);

ALTER TABLE air_passengers_details
ADD CONSTRAINT fk_p_details_passenger_id
FOREIGN KEY (passenger_id)
REFERENCES air_passengers(passenger_id);

-- Indexes
CREATE INDEX idx_al_base_ap_id
ON air_airlines(base_airport_id);
  
CREATE INDEX idx_ap_ap_type_id
ON air_airplanes(airplane_type_id);
  
CREATE INDEX idx_f_fno
ON air_flights(flightno);
CREATE INDEX idx_f_al_id
ON air_flights(airline_id);
CREATE INDEX idx_f_from_apo_id
ON air_flights(from_airport_id);
CREATE INDEX idx_f_to_apo_id
ON air_flights(to_airport_id);
CREATE INDEX idx_f_apa_id
ON air_flights(airplane_id);
CREATE INDEX idx_f_departure
ON air_flights(departure);
  
CREATE INDEX idx_fs_al_id
ON air_flights_schedules(airline_id);
CREATE INDEX idx_fs_from_apo_id
ON air_flights_schedules(from_airport_id);
CREATE INDEX idx_fs_to_apo_id
ON air_flights_schedules(to_airport_id);

CREATE INDEX idx_b_p_id
ON air_bookings(passenger_id);
CREATE INDEX idx_b_f_id
ON air_bookings(flight_id);
-- Index requisitado no enunciado
CREATE UNIQUE INDEX ak_air_bookings_flightidseat on air_bookings(
case
    when seat is not null then flight_id
    else null
end,
case
    when seat is not null then seat
    else null
end
);

CREATE INDEX idx_pd_country
  ON air_passengers_details(country);
CREATE INDEX idx_pd_birthdate
  ON air_passengers_details(birthdate);

























