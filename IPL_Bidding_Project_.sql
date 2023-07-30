use ipl;

# 1.	Show the percentage of wins of each bidder in the order of highest to lowest percentage.
select bidder_name,
       count(if(bid_status = 'won',1,null)) as won,
       count(A.BIDDER_ID) as total,
       round(count(if(bid_status = 'won',1,null))/count(A.bidder_id)*100,2) as win_percentage
from IPL_BIDDING_DETAILS A inner join IPL_BIDDER_DETAILS B
on A.BIDDER_ID = B.BIDDER_ID
group by A.BIDDER_ID
order by win_percentage desc;

# 2.	Display the number of matches conducted at each stadium with the stadium name and city.
select STADIUM_NAME, CITY, count(*) as no_of_matches
from IPL_MATCH A inner join IPL_MATCH_SCHEDULE B inner join IPL_STADIUM C
on A.MATCH_ID = B.MATCH_ID and B.STADIUM_ID = C.STADIUM_ID
group by C.STADIUM_ID;

# 3.	In a given stadium, what is the percentage of wins by a team which has won the toss?

-- analysis
# Edge Case: where count of ipl_match is 120 but count of ipl_match_schedule is 122 (where 2 scheduled matches got cancelled)
# scheduled_id = (10082, 10008)  and match_id = (1110, 1016) are cancelled but count in the total column to get the percentage

-- win by a team and won the toss : calculated by win_team and win_toss / total(win_team and win_toss | lost_team and lost_toss | got_cancelled)
select C.STADIUM_NAME,
       count(if(match_winner = TOSS_WINNER, 1, null)) as won,
       count(*) as total,
       round((count(if(MATCH_WINNER = TOSS_WINNER,1,null))/count(*))*100,2) as won_percentage
from IPL_MATCH A inner join IPL_MATCH_SCHEDULE B inner join IPL_STADIUM C
on A.MATCH_ID = B.MATCH_ID and B.STADIUM_ID = C.STADIUM_ID
group by C.STADIUM_ID;

# 4.	Show the total bids along with the bid team and team name.
select A.bid_team, B.TEAM_NAME, count(*) as total_bids
from IPL_BIDDING_DETAILS A inner join IPL_TEAM B
on A.BID_TEAM = B.TEAM_ID
group by A.BID_TEAM;

# 5.	Show the team id who won the match as per the win details.
select TEAM_ID, TEAM_NAME,WIN_DETAILS
from IPL_MATCH A inner join IPL_TEAM B
on trim(left(substr(WIN_DETAILS,6),position(' ' in substr(win_details,6)))) = B.REMARKS; -- won the match as per win_details

-- another approach : using where clause
select TEAM_ID, TEAM_NAME,WIN_DETAILS
from IPL_MATCH A inner join IPL_TEAM B
on A.WIN_DETAILS like concat('%',B.REMARKS,'%');

# 6.	Display total matches played, total matches won and total matches lost by the team along with its team name.

-- analysis
# Edge Case1 : some of the match_winner having the team_id instead of team_id1 or team_id2
# Edge Case2 : approach1 is based on ipl_team_standings and approach2 is based on ipl_match table

-- approach1 : IPL_TEAM_STANDINGS has total matches_played, matches_won, matches_lost
select B.TEAM_NAME, sum(MATCHES_WON) as won, sum(MATCHES_LOST) as lost, sum(MATCHES_PLAYED) as total
from IPL_TEAM_STANDINGS A inner join IPl_TEAM B
on A.TEAM_ID = B.TEAM_ID
group by A.TEAM_ID;

-- approach2 : IPL_MATCH has team_id1 and team_id2 based on that total, won, lost can be calculated
with wontb as (select (case when MATCH_WINNER = 1 then TEAM_ID1 when MATCH_WINNER = 2 then TEAM_ID2 else MATCH_WINNER end) as won, count(*) as wct from IPL_MATCH group by won),
     losttb as (select (case when MATCH_WINNER = 1 then TEAM_ID2 when MATCH_WINNER = 2 then TEAM_ID1 else if(MATCH_WINNER = TEAM_ID1,TEAM_ID2, TEAM_ID1) end) as lost, count(*) as lct from IPL_MATCH group by lost)

select TEAM_NAME, wct as won, lct as lost, wct+lct as total
from wontb inner join losttb inner join IPL_TEAM
on wontb.won = losttb.lost and IPL_TEAM.TEAM_ID = wontb.won
order by wontb.won;

# 7.	Display the bowlers for the Mumbai Indians team.
-- Edge Case: the team_id is different from the remarks column (best practice is using remarks is reliable)
select team_id, A.PLAYER_ID, PERFORMANCE_DTLS
from IPL_TEAM_PLAYERS A inner join IPL_PLAYER B
on A.PLAYER_ID = B.PLAYER_ID and A.REMARKS like '%MI%' and A.PLAYER_ROLE like '%Bowler%';

# 8.	How many all-rounders are there in each team, Display the teams with more than 4 all-rounders in descending order.
select replace(REMARKS,'TEAM - ','') as REMARKS, count(*) as total
from IPL_TEAM_PLAYERS
where PLAYER_ROLE like '%All-Rounder%'
group by REMARKS
having total > 4
order by total desc;