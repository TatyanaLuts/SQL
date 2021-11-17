/* 1. � ����� ������� ������ ������ ���������? */

select 
	city -- ������� ������
from airports a -- �� ������� ���������
group by city --���������� �� ������
having count (airport_code) > 1 -- ������� ���������� ���������� � ������ ������ � ������� ������,��� ���������� ������ 1.

/* 2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������? ���������� ������������ ��������� */

select distinct -- �������� ���������� ��������, ����� ������ ������������� �������� ������
	f2.departure_airport, -- �������� ������
	f2.arrival_airport -- �������� ������
	from flights f2 
inner join -- �������� inner, ����� ������� ��������� � �������, �� ������� ������� � ������������ ���������� �����
	(select aircraft_code -- ������� ������ �������� � ������������ ���������� ������ (range) �� ������� "aircrafts � �������"
	from aircrafts 
	where "range" = 
		(select max("range") from aircrafts)) as r on f2.aircraft_code = r.aircraft_code 

/* 3. ������� 10 ������ � ������������ �������� �������� ������. ���������� ������������ �������� LIMIT */		

select flight_no, -- ������� ����� �����
	(actual_departure - scheduled_departure) as delay -- ������� ����������������� �������� ��� ������� ����� (�� ������������ ������� ������ �������� �������� ����� ������)
from flights -- �� ������� �����
where (actual_departure - scheduled_departure) is not null -- ����������� �������, � ������� ��� ������ �� ������������ ������ �, �������������, ���������� ���������� ����������������� ��������.
order by delay desc -- ��������� ����������������� �������� �� �������� 
limit 10 -- � ������� LIMIT 10 ������ ������ 10 �����, ��������������� ��������� SELECT

/* 4. ����������, ���� �� �����, �� ������� �� ���� �������� ���������� ������. ������������ ������ ��� JOIN */

select book_ref, boarding_no --������� � ������������, � ����������� ������
from tickets t -- �� ������� ������
left join boarding_passes bp using(ticket_no) -- ������������ ���������� ������ �� � ������ 
where boarding_no is null -- �������� ������� NULL, �� ���� �����, �� ������� �� ���� �������� ���������� ������ � ������, ���������� �� ����� �����

/* 5. ����� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������. �������� ������� � ������������� ������. ������������ ������� ������� � ���������� */
select f.flight_id, --������������� �����
	f.departure_airport, --�������� ������
	f.scheduled_departure, --���� � ����� ������
	(seat_all - seat_busy) as seat_free, --��������� ����� = ���-�� ���� ���� � �������� - ���-�� ������� ���� � ������ ��������
	((seat_all - seat_busy)*100/seat_all) as share, -- % ��������� ���� � ������ ���������� ���� � �������� (����)
	seat_busy, --������� �����
	sum(seat_busy) over (partition by f.departure_airport, date(f.scheduled_departure) order by f.scheduled_departure) as itog --������������� ���� (���������� �������, ���������� �� ����������� ��������� � ���������� ����(������� date - �������� �����))
from flights f 
join ( -- ������������ ���������� ���� � �������� (��� ������ ������ �������� ���� ����������)
	select s.aircraft_code, -- ������ ��������
	count(seat_no) as seat_all --������� ���������� ���� � ���������� ������ ��������
	from seats s -- �� ������� �����
	group by s.aircraft_code) s --���������� �� ������ ��������
	on f.aircraft_code = s.aircraft_code
join ( -- ������������ ���������� ������� ���� � ������ �����
	select bp.flight_id, -- ���� �� ������� ���������� ������
	count(seat_no) as seat_busy -- ������� ���������� ������� ���� � ������������ � ����������� �������� 
	from boarding_passes bp
	group by bp.flight_id) bp -- ���������� �� ������
	on  f.flight_id = bp.flight_id

/* 6. ����� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������. ������������ ��������� � �������� ROUND */

select 
	aircraft_code,--������� ��� ��������
	round(count(aircraft_code)*100.00/ -- ���������� ��������� ������� ���� �������� �������� �� 100.00 (����� �� �������� 0 ��� ������� � ".00" ����� �� �������� �������� ����� ������� � �� �������� ���������� ��������) � ����� �� 
    (select count(aircraft_code) -- ����� ���������� ��������� ���� ����� ��������� (������� ����� ���������) � ��������� �� �����.
    from flights)) as share -- ���������� ����� ���������� ����
from 
    flights -- �� ������� �����
group by aircraft_code -- ���������� �� ���� ��������

/* 7. ���� �� ������, � ������� ����� ��������� ������-������� �������, ��� ������-������� � ������ ��������?. ������������ CTE */

with cte_e as (
	select flight_id, fare_conditions, amount --������� ����, ����� ������������, ��������� ��������.
	from ticket_flights tf --�� ������� ��������
	group by flight_id, fare_conditions, amount --����������, ����� ������ �����
	having fare_conditions = 'Economy'), --�������� ������-�����
cte_b as (
	select flight_id, fare_conditions, amount --������� ����, ����� ������������, ��������� ��������.
	from ticket_flights tf --�� ������� ��������
	group by flight_id, fare_conditions, amount --����������, ����� ������ �����
	having fare_conditions = 'Business'), --�������� �������-�����
cte_c as (
	select flight_id, arrival_airport, a.city -- ������������ ������ � ��������������� �����
	from flights f 
	left join airports a on f.arrival_airport = a.airport_code --������������ ������ � �������������� �����
)
select cte_c.city -- ������� ������
from cte_e
join cte_b using(flight_id) -- ������� �����, ��� ���� � ������-�����, � �������
left join cte_c using(flight_id)  -- 
where cte_b.amount < cte_e.amount --��� ���������, �������-������ �������, ��� ������-������ (��������� �������� �� cte_e ������-������ ���������� �� ���������� �� �������-������ cte_b �� �������������� �����)
-- �����: ������ ������ ���.

/* 8. ����� ������ �������� ��� ������ ������? ������������ ��������� ������������ � ����������� FROM, �������������� ��������� �������������, �������� EXCEPT) */
create or replace view city_all as --������ ������������� ��� ������, � ������� ���� ���������
	select city
	from airports

create or replace view city_flights as -- ������� �������������, � ������� ������ �� ���� ������ (���� ���������� ������/�������, ������ ������/�������)
	select flight_id, flight_no, departure_airport, a.city as city_dep, arrival_airport, ai.city as city_arr 
	from flights f -- � ������� flights ��������� ������ ���������� 
	left join airports a on f.departure_airport = a.airport_code
	left join airports ai on f.arrival_airport = ai.airport_code

select * 
from (select a.city as city_d, c.city as city_a -- �������� ������, ����� �������� ��� ������ ������ (� ����������� ����������)
	from airports a, city_all c --������� ��������� ������������ - ��� ��������� �������� ����� ������ - ����� �������
	where a.city <> c.city) as ttt --��������� ��������, ����� ����� ������ � ����� ������� - ���� � ��� ��, �.�. ����� ������ �� ����� ����
except select city_dep, city_arr -- ������� ������� ����� ���������� ������������� (��� ��������� �������� ����� ������ - ����� �������) � ��������� ������� �� ������ (������ ������ - �������)
from city_flights 


/* 9. ��������� ���������� ����� �����������, ���������� ������� �������.�������� � ���������� ������������ ���������� ��������� � ���������, ������������� ��� �����. ������������ �������� RADIANS ��� ������������� sind/cosd */

select departure_airport, arrival_airport, ac."range", --������� ����� ������, �������, ���������� ��������� �������� �������� �� ����� � ���������� ����� �����������
	round(acos(sin(radians(a.latitude))*sin(radians(ai.latitude)) + cos(radians(a.latitude))*cos(radians(ai.latitude))*cos(radians(a.longitude) - radians(ai.longitude)))*6371) as distance
from flights f 
left join airports a on f.departure_airport = a.airport_code 
left join airports ai on f.arrival_airport = ai.airport_code
left join aircrafts ac on f.aircraft_code = ac.aircraft_code
group by departure_airport, arrival_airport, ac."range", distance -- ����������, ����� ������ �������

