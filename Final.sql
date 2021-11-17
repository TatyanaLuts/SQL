/* 1. В каких городах больше одного аэропорта? */

select 
	city -- выводим города
from airports a -- из таблицы Аэропорты
group by city --группируем по городу
having count (airport_code) > 1 -- считаем количество аэропортов в каждом городе и выводим города,где аэропортов больше 1.

/* 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета? Необходимо использовать подзапрос */

select distinct -- выбираем уникальные значения, чтобы убрать повторяющиеся значения рейсов
	f2.departure_airport, -- аэропорт вылета
	f2.arrival_airport -- аэропорт прилёта
	from flights f2 
inner join -- выбираем inner, чтобы выбрать аэропорты с рейсами, на которых самолёты с максимальной дальностью полёта
	(select aircraft_code -- находим модель самолета с максимальной дальностью полета (range) из таблицы "aircrafts – самолёты"
	from aircrafts 
	where "range" = 
		(select max("range") from aircrafts)) as r on f2.aircraft_code = r.aircraft_code 

/* 3. Вывести 10 рейсов с максимальным временем задержки вылета. Необходимо использовать оператор LIMIT */		

select flight_no, -- выводим номер рейса
	(actual_departure - scheduled_departure) as delay -- находим продолжительность задержки для каждого рейса (из фактического времени вылета вычитаем плановое время вылета)
from flights -- из таблицы рейсы
where (actual_departure - scheduled_departure) is not null -- отбрасываем позиции, в которых нет данных по фактическому вылету и, сответственно, невозможно определить продолжительность задержки.
order by delay desc -- сортируем продолжительность задержки по убыванию 
limit 10 -- с помощью LIMIT 10 вернет первые 10 строк, соответствующих критериям SELECT

/* 4. Определить, были ли брони, по которым не были получены посадочные талоны. Использовать верный тип JOIN */

select book_ref, boarding_no --выводим № бронирования, № посадочного талона
from tickets t -- из таблицы Билеты
left join boarding_passes bp using(ticket_no) -- присоединяем посадочные талоны по № билета 
where boarding_no is null -- выбираем значени NULL, то есть брони, по которым не были получены посадочные талоны и узнаем, существуют ли такие брони

/* 5. Найти свободные места для каждого рейса, их % отношение к общему количеству мест в самолете. Добавить столбец с накопительным итогом. Использовать Оконную функцию и Подзапросы */
select f.flight_id, --идентификатор рейса
	f.departure_airport, --аэропорт вылета
	f.scheduled_departure, --дата и время вылета
	(seat_all - seat_busy) as seat_free, --свободные места = кол-во всех мест в самолете - кол-во занятых мест в каждом самолете
	((seat_all - seat_busy)*100/seat_all) as share, -- % свободных мест к общему количество мест в самолете (доля)
	seat_busy, --занятые места
	sum(seat_busy) over (partition by f.departure_airport, date(f.scheduled_departure) order by f.scheduled_departure) as itog --накопительный итог (количество человек, вылетевших из конкретного аэропорта в конкретный день(поэтому date - отсекаем время))
from flights f 
join ( -- присоединяем количество мест в самолете (для каждой модели самолета свое количесвто)
	select s.aircraft_code, -- модель самолета
	count(seat_no) as seat_all --считаем количество мест в конкретной модели самолета
	from seats s -- из таблицы Места
	group by s.aircraft_code) s --группируем по модели самолета
	on f.aircraft_code = s.aircraft_code
join ( -- присоединяем количество занятых мест в каждом рейсе
	select bp.flight_id, -- рейс из таблицы Посадочные талоны
	count(seat_no) as seat_busy -- считаем количество занятых мест в соответствии с посадочными талонами 
	from boarding_passes bp
	group by bp.flight_id) bp -- группируем по рейсам
	on  f.flight_id = bp.flight_id

/* 6. Найти процентное соотношение перелетов по типам самолетов от общего количества. Использовать подзапрос и оператор ROUND */

select 
	aircraft_code,--выводим код самолета
	round(count(aircraft_code)*100.00/ -- количество перелетов каждого типа самолета умножаем на 100.00 (чтобы не получить 0 при делении и ".00" чтобы не потерять значения после запятой и не получить искаженные значения) и делим на 
    (select count(aircraft_code) -- общее количество перелетов всех типов самолетов (находим через подзапрос) и округляем до целых.
    from flights)) as share -- показатель будет называться Доля
from 
    flights -- из таблицы Рейсы
group by aircraft_code -- группируем по коду самолета

/* 7. Были ли города, в которые можно добраться бизнес-классом дешевле, чем эконом-классом в рамках перелета?. Использовать CTE */

with cte_e as (
	select flight_id, fare_conditions, amount --выводим рейс, класс обслуживания, стоимость перелета.
	from ticket_flights tf --из таблицы Перелеты
	group by flight_id, fare_conditions, amount --группируем, чтобы убрать дубли
	having fare_conditions = 'Economy'), --выбираем эконом-класс
cte_b as (
	select flight_id, fare_conditions, amount --выводим рейс, класс обслуживания, стоимость перелета.
	from ticket_flights tf --из таблицы Перелеты
	group by flight_id, fare_conditions, amount --группируем, чтобы убрать дубли
	having fare_conditions = 'Business'), --выбираем бизнесс-класс
cte_c as (
	select flight_id, arrival_airport, a.city -- сопоставляем города с индетификатором рейса
	from flights f 
	left join airports a on f.arrival_airport = a.airport_code --присоединяем города к индетификатору рейса
)
select cte_c.city -- выводим города
from cte_e
join cte_b using(flight_id) -- выводим рейсы, где есть и эконом-класс, и бизнесс
left join cte_c using(flight_id)  -- 
where cte_b.amount < cte_e.amount --где стоимость, бизнесс-класса дешевле, чем эконом-класса (стоимость перелета из cte_e эконом-класса сравниваем сл стоимостью из бизнесс-класса cte_b по индетификатору рейса)
-- Ответ: такого города нет.

/* 8. Между какими городами нет прямых рейсов? Использовать Декартово произведение в предложении FROM, Самостоятельно созданные представления, Оператор EXCEPT) */
create or replace view city_all as --создаём представление Все города, в которых есть аэропорты
	select city
	from airports

create or replace view city_flights as -- создаем представление, в котором данные по всем рейсам (коды аэропортов вылета/прилета, города вылета/прилета)
	select flight_id, flight_no, departure_airport, a.city as city_dep, arrival_airport, ai.city as city_arr 
	from flights f -- к таблице flights добавляем города аэропортов 
	left join airports a on f.departure_airport = a.airport_code
	left join airports ai on f.arrival_airport = ai.airport_code

select * 
from (select a.city as city_d, c.city as city_a -- получаем города, между которыми нет прямых рейсов (с зеркальными значениями)
	from airports a, city_all c --находим Декартово произведение - все возможные вариации город вылета - город прилета
	where a.city <> c.city) as ttt --отсеиваем варианты, когда город вылета и город прилета - один и тот же, т.к. таких рейсов не может быть
except select city_dep, city_arr -- находим разницу между Декартовым произведением (все возможные варианты город вылета - город прилета) и реальными данными по рейсам (города вылета - прилета)
from city_flights 


/* 9. Вычислить расстояние между аэропортами, связанными прямыми рейсами.Сравнить с допустимой максимальной дальностью перелетов в самолетах, обслуживающих эти рейсы. Использовать Оператор RADIANS или использование sind/cosd */

select departure_airport, arrival_airport, ac."range", --выводим город вылета, прилета, допустимую дальность перелета самолета на рейсе и расстояние между аэропортами
	round(acos(sin(radians(a.latitude))*sin(radians(ai.latitude)) + cos(radians(a.latitude))*cos(radians(ai.latitude))*cos(radians(a.longitude) - radians(ai.longitude)))*6371) as distance
from flights f 
left join airports a on f.departure_airport = a.airport_code 
left join airports ai on f.arrival_airport = ai.airport_code
left join aircrafts ac on f.aircraft_code = ac.aircraft_code
group by departure_airport, arrival_airport, ac."range", distance -- группируем, чтобы убрать повторы

