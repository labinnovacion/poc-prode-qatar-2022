//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
    
    /*** Tipos predefinidos de datos    ***/
enum MatchState { notplayed, played }
enum MatchResult { RESERVED, A_WINS, B_WINS, TIED}
enum MatchType {_Group, _8VO,_4TO,_Semifinal,_Final}
enum MatchPenalty {RESERVED,A_WINS,B_WINS}
enum BetState { NO_PRIZE, UNCLAIMED, CLAIMED}

struct Team {
    string id;
    string name;
    uint256 status;
}

struct Match
{
    string id;
    uint256 matchDate;
    MatchState status;
    MatchResult result;
    Team teamAid;
    Team teamBid;
    uint8 goalA;
    uint8 goalB;
    MatchType typeMatch;
    MatchPenalty resultPenalty;
}

struct Bet{
    string MatchId;
    uint8 goalA;
    uint8 goalB;
    MatchPenalty resultPenalty;
    BetState _state;
}