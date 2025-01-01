ÿ/*retrieved the corresponding crime scene report from the police departments database with the information I remember
(date:20180115, city:SQL City,type:murder)*/.   
SELECT * 
FROM crime_scene_report 
WHERE date="20180115" AND city="SQL City" AND type="murder";
/*From my query I realized there were two witnesses:Security footage shows that there were 2 witnesses. 
The first witness lives at the last house on "Northwestern Dr". 
The second witness, named Annabel, lives somewhere on "Franklin Ave"*/.


-- I used the following query to get the ID number of the two witnesscrime_scene_report
--First witness:
SELECT id person_id
FROM person 
WHERE address_number=(SELECT MAX(address_number) 
FROM person 
WHERE address_street_name = 'Northwestern Dr');
--Then I created a TEMP TABLE for this 
CREATE TEMP TABLE first_witness AS 
SELECT id person_id
FROM person 
WHERE address_number=(SELECT MAX(address_number) 
FROM person 
WHERE address_street_name = 'Northwestern Dr');


--Second witness
SELECT id person_id
 FROM person 
WHERE name LIKE 'Annabel %' AND address_street_name='Franklin Ave';
--Then I also created a TEMP TABLE for this
CREATE TEMP TABLE second_witness AS 
SELECT id person_id
 FROM person 
WHERE name LIKE 'Annabel %' AND address_street_name='Franklin Ave';


--Then i Queried the interview table to get the statements from the two witnesses with the following query:
--First witness: 
SELECT transcript FROM interview 
WHERE person_id IN (SELECT person_id FROM first_witness)
/*RESULT: I heard a gunshot and then saw a man run out. He had a "Get Fit Now Gym" bag. 
The membership number on the bag started with "48Z". Only gold members have those bags. 
The man got into a car with a plate that included "H42W"*/


--Second witness:
SELECT transcript FROM interview 
WHERE person_id IN (SELECT person_id FROM second_witness)
/*RESULT:I saw the murder happen, and I recognized the killer from my gym 
when I was working out last week on January the 9th*/


--From the first statement, I queried the get_fit_now_member table next with the following query:
SELECT id, name 
FROM get_fit_now_member 
WHERE id LIKE '48Z%' AND membership_status='gold';
/*RESULTS:
  ID         NAME
"48Z7A"         "Joe Germuska"
"48Z55"         "Jeremy Bowers"


Then I created a TEMP TABLE for the above query*/:
CREATE TEMPORARY TABLE membership_id_name AS 
SELECT id, name 
FROM get_fit_now_member 
WHERE id LIKE '48Z%' AND membership_status='gold';


/*I also investigated my second statement by querying the get_fit_now_check_in table
and joined it with the get_fit_now_member table to get the list of people who were at the gym on the 9th of January*/:
SELECT name
FROM get_fit_now_check_in 
JOIN get_fit_now_member
ON get_fit_now_check_in.membership_id=get_fit_now_member.id
WHERE check_in_date=20180109 ;
/*RESULTS: "Shondra Ledlow"
"Zackary Cabotage"
"Sarita Bartosh"
"Adriane Pelligra"
"Burton Grippe"
"Blossom Crescenzo"
"Carmen Dimick"
"Joe Germuska"
"Jeremy Bowers"
"Annabel Miller"
 */
--Then I also created a TEMPORARY TABLE for this query
CREATE TEMPORARY TABLE gym_members_available_09 AS 
SELECT name
FROM get_fit_now_check_in 
JOIN get_fit_now_member
ON get_fit_now_check_in.membership_id=get_fit_now_member.id
WHERE check_in_date=20180109;
--I used 2018 as the year for this statement because that is our current year while carrying out the investigation.


/*I queried the persons table and joined it to the drivers_liescence table 
to get the details of the person amongst the names gotten so far,
that drives a car with a plate number with H42W as part of the number according to the first witness,
then I filtered the results by the remaining statements given by witnesses
which are the results in the temporary table gym_members_available_09 and membership_id_name*/ :
SELECT person.id, person.name, person.ssn, person.license_id
FROM person
JOIN drivers_license ON drivers_license.id = person.license_id
WHERE drivers_license.plate_number LIKE '%H42W%'
AND person.name IN (SELECT name FROM gym_members_available_09)
AND person.name IN (SELECT name FROM membership_id_name);
--Results:id:67318,name:Jeremy Bowers,ssn:871539279,license_id: 423327
--I created a temp table for Jeremy's details.
CREATE TEMP TABLE Jeremy AS 
SELECT person.id, person.name, person.ssn, person.license_id
FROM person
JOIN drivers_license ON drivers_license.id = person.license_id
WHERE drivers_license.plate_number LIKE '%H42W%'
AND person.name IN (SELECT name FROM gym_members_available_09)
AND person.name IN (SELECT name FROM membership_id_name);


--From the above query I found out Jeremy Bowers committed the crime


--I also checked for Jeremy's statement from the interview table but first inserted Jeremy's information into the solutions table:
INSERT INTO solution (user, value)
VALUES (67318, 'Jeremy Bowers');
--Get Jeremy's statement:
SELECT transcript 
FROM interview 
Join solution
ON solution.user=interview.person_id
WHERE person_id IN (SELECT person_id FROM Jeremy)
/*RESULT:I was hired by a woman with a lot of money.
I don't know her name but I know she's around 5'5" (65") or 5'7" (67").
She has red hair and she drives a Tesla Model S. 
I know that she attended the SQL Symphony Concert 3 times in December 2017.*/
--found out Jeremy was hired for the crime,so now I have to figure out who hired him(this case is getting more interesting by the query)


--I queried the drivers_liescence table and Joined it with person table first to get the person_id of the possible suspects:
SELECT person.name,person.ssn,person.id
FROM drivers_license
JOIN person
ON drivers_license.id=person.license_id
WHERE drivers_license.gender='female'
AND car_make='Tesla'
AND car_model='Model S'
AND hair_color='red'
AND height IN(65,66,67)
/*RESULT:
   NAME                SSN                ID
 "Red Korb"                "961388910"                "78881"
"Regina George"            "337169072"                "90700"
"Miranda Priestly"        "987756388"                "99716"*/
--Then i created a TEMPORARY TABLE for the above query
CREATE TEMP TABLE suspected_list_of_killer_employer AS 
SELECT person.name,person.ssn,person.id
FROM drivers_license
JOIN person
ON drivers_license.id=person.license_id
WHERE drivers_license.gender='female'
AND car_make='Tesla'
AND car_model='Model S'
AND hair_color='red'
AND height IN(65,66,67)


/* I queried the facebook_event_checkin table and Joined with the person and the income table to get 
the annual income, name of the person who saw SQL Symphony Concert in December 2017, gender(female), 
has red hair, drives a Tesla Model S,and a height around 65 and 67(which means it can be 65,66,67) 
but I already had most of this narrowed down so I linked the table that had the information 
which is the temporary table(suspected_list_of_killer_employee)*/
SELECT person.ssn,person.name,income.annual_income
FROM facebook_event_checkin
JOIN person
ON facebook_event_checkin.person_id=person.id
JOIN income
ON income.ssn=person.ssn
WHERE facebook_event_checkin.event_name = 'SQL Symphony Concert'
AND facebook_event_checkin.date LIKE '201712%'
AND id IN (SELECT id FROM suspected_list_of_killer_employer)
GROUP BY person.id
HAVING COUNT(*)=3


/*RESULTS:
    SSN              NAME                ANNUAL SALARY
"987756388"           "Miranda Priestly"              "310000"


Inserted this to the solution's table.


So,from my investigation I found out that Jeremy Bowers commited the crime,
but he was hired by Miranda Priestly to commit the crime.*/