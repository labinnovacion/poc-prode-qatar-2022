//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------
import "../ERC20Token/ICryptoLink.sol"; //Interface de CryptoLink
import "../Allowlist/IAllowlist.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./DataTypesDeclaration.sol";
import "hardhat/console.sol";

contract Prode is Pausable, AccessControl {
    /***    Roles   ***/

    //Tiene permisos para modificar partidos
    bytes32 public constant MATCH_ROLE = keccak256("MATCH_ROLE");

    /***    Constantes  ***/
    address public erc20_contract = 0xbf6c50889d3a620eb42C0F188b65aDe90De958c4; //TOKEN Cryptolink2 Address
    address public erc721_contract = 0xbf6c50889d3a620eb42C0F188b65aDe90De958c4; //SebaNFT Address
    address public allowlist_contract =
        0xbf6c50889d3a620eb42C0F188b65aDe90De958c4; //AllowList contract
    uint deadline = 1 hours;

    string public constant ERROR_MATCH_PLAYED = "Partido ya jugado.";
    string public constant ERROR_MATCH_NOT_PLAYED = "Partido no jugado.";
    string public constant ERROR_ALREADY_CLAIMED = "Apuesta ya reclamada.";
    string public constant ERROR_OUTATIME =
        "Fuera del horario permitido para apostar.";
    string public constant ERROR_NOT_BET = "Partido sin apuesta.";

    /*** En fase de grupos: */
    uint8 public constant PRIZE_GROUP_EXACT_MATCH = 12; //Acierto total (marcador y equipo)
    uint8 public constant PRIZE_GROUP_WINNER_NOSCORE = 5; //Acierto equipo pero no marcador
    uint8 public constant PRIZE_GROUP_WINNER_ONE_SCORE = 7; //Acierto equipo y un solo marcador
    uint8 public constant PRIZE_GROUP_ONE_SCORE = 2; //Acierto un solo marcador

    /*** En octavos, cuartos, semi y final */
    uint8 public constant PRIZE_MATCH_NO_PENALTIES = 9; //Acierto del resultado sin penales
    uint8 public constant PRIZE_MATCH_PENALTIES = 9 + 5; //Acierto total con penales
    uint8 public constant PRIZE_ONLY_PENALTIES = 5; //Acierto solo penales

    /***    Mapa de ID-> Team ***/
    //No es tan necesario, pero está bueno saber a quiénes estamos apostando.
    mapping(string => Team) public teams;

    /***    Mapa de ID -> Partido    ***/
    mapping(string => Match) public matches;

    /*** Datos del user -> match -> bet 
    La idea es que se pueda mapear***/
    mapping(address => mapping(string => Bet)) public gameData;

    /*Eventos*/
    event ProdeERC20ContractSet(
        address indexed newContract,
        address indexed oldContract
    );
    event ProdeERC721ContractSet(
        address indexed newContract,
        address indexed oldContract
    );

    event AllowlistContractSet(
        address indexed newContract,
        address indexed oldContract
    );

    event BetCreated(
        address indexed player,
        string matchID,
        uint8 goalA,
        uint8 goalB,
        MatchPenalty penalty,
        uint betAmount
    );
    event BetClaimed(address indexed player, string matchID, uint claimedPrize);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MATCH_ROLE, _msgSender());
    }

    function setERC20Contract(address _erc20_contract)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit ProdeERC20ContractSet(_erc20_contract, erc20_contract);
        erc20_contract = _erc20_contract;
    }

    function setERC721Contract(address _erc721_contract)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit ProdeERC721ContractSet(_erc721_contract, erc721_contract);
        erc20_contract = _erc721_contract;
    }

    function setAllowlistContract(address _allowlist_contract)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        emit AllowlistContractSet(_allowlist_contract, allowlist_contract);
        allowlist_contract = _allowlist_contract;
    }

    function setDeadline(uint time) public onlyRole(DEFAULT_ADMIN_ROLE) {
        deadline = time;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /***    Funciones del PRODE    ***/
    /**
     * @dev bet2/apostar: inserta en el array de apuestas una apuesta
     * @param matchId ID del partido
     * @param goalA Cantidad de goles del equipo A (Local?)
     * @param goalB Cantidad de goles del equipo B (Visitante?)
     * @param penaltyResult Resultado de los penales {0:RESERVED,1:A_WINS,2:B_WINS}
     * @param betAmount Cantidad de tokens apostados
     */
    function bet2(
        string calldata matchId,
        MatchPenalty penaltyResult,
        uint8 goalA,
        uint8 goalB,
        uint betAmount
    ) public checkForPlayer {
        //Debemos chequear que el Match no haya sido jugado.
        require(
            matches[matchId].status != MatchState.played,
            ERROR_MATCH_PLAYED
        );
        //Debemos chequear que el Match esté en hora para apostarse.
        require(
            matches[matchId].matchDate >= block.timestamp + deadline,
            ERROR_OUTATIME
        );


        //Lógica de la apuesta

        if (gameData[_msgSender()][matchId].betAmount < betAmount) {
            //Apuesta nueva o incrementa, hay que quitarle plata al usuario
            //Acá le quito tokens.
            ICryptoLink(erc20_contract).transferFrom(
                _msgSender(),
                address(this),
                betAmount - gameData[_msgSender()][matchId].betAmount
            );
            gameData[_msgSender()][matchId].betAmount = betAmount;
        } else {
            if (gameData[_msgSender()][matchId].betAmount > betAmount) {
                //Está reduciendo apuesta, devolver plata.
                gameData[_msgSender()][matchId].betAmount = betAmount;
                ICryptoLink(erc20_contract).transfer(
                    _msgSender(),
                    gameData[_msgSender()][matchId].betAmount - betAmount
                );
            } //No hace falta este ELSE, porque solo hay que asignar los goles.
        }
        gameData[_msgSender()][matchId].goalA = goalA;
        gameData[_msgSender()][matchId].goalB = goalB;
        gameData[_msgSender()][matchId].resultPenalty = penaltyResult;
        gameData[_msgSender()][matchId].isValid = true;
        emit BetCreated(
            _msgSender(),
            matchId,
            goalA,
            goalB,
            penaltyResult,
            betAmount
        );
    }

    /**
     * @dev claimPrize/reclamar premio: reclama el premio, minteando los tokens
     * que correspondan para esa apuesta, y si es necesario, el NFT del 
     * partido, sólo si el acierto fue EXACTO.
     * Lógica de premios:
     * Para la Etapa de Grupos será de la siguiente manera: 

a) De acertar el ganador / perdedor o empate y el resultado exacto, se obtendrán x12 puntos.
b) De acertar el ganador / perdedor / empate pero no el marcador de ninguno de los equipos, se obtendrán x5 puntos
c) De acertar el ganador o perdedor y la cantidad de goles de uno de los dos equipos, se obtendrán x7 puntos.
d) Acertando la cantidad de goles de uno de los dos equipos pero no el ganador, se obtienen x2 puntos.
e) De no realizar ninguno de los aciertos mencionados, no se obtienen puntos.

De Cuartos de Final en adelante, Se podrán pronosticar empates y seleccionar un ganador por penales.

a) De acertar el resultado exacto, se obtendrán x9 puntos. De acertar también el ganador de los penales se adicionan x5 puntos más.
b) De no acertar el resultado exacto y solo acertar el ganador de los penales se obtienen x5 puntos.
c) De no acertar el resultado del partido y no acertar el ganador por penales no se obtendrán puntos.

     * @param matchId ID del partido.
     * @return erc20_prize_amount Valor del premio.
     * @return mintNft Si hubo NFT Minteado, el ID, sino devuelve 0.
     */
    function claimPrize(string calldata matchId)
        public
        checkForPlayer
        returns (uint erc20_prize_amount, bool mintNft)
    {
        //Debemos chequear que el Match no haya sido jugado.
        require(
            matches[matchId].status == MatchState.played,
            ERROR_MATCH_NOT_PLAYED
        );
        //Debemos comprobar que no se haya claimeado.
        require(
            !gameData[_msgSender()][matchId].claimed,
            ERROR_ALREADY_CLAIMED
        );
        //Debemos comprobar que haya una apuesta anterior.
        require(gameData[_msgSender()][matchId].isValid, ERROR_NOT_BET);

        gameData[_msgSender()][matchId].claimed = true;

        /*** Cálculo de los premios ***/
        mintNft = false;
        (erc20_prize_amount, mintNft) = checkPrize(_msgSender(), matchId);

        //TOKEN ERC20: Si es necesario mintearle tokens al usuario...
        //Si se usara DAI u otro Token, habría que cambiar la fórmula.
        //En este caso, el prode puede mintear.
        ICryptoLink(erc20_contract).mint(
            _msgSender(),
            erc20_prize_amount * gameData[_msgSender()][matchId].betAmount
        );

        if (mintNft) {
            //Tenemos que mintear el NFT
            // ACá se mintearía el NFT de Seba
            //INFT(erc721_contract).mint(_msgSender(),matchId);
        }

        return (erc20_prize_amount, mintNft);
    }

    function checkPrize(address player, string calldata matchId)
        public
        view
        returns (uint erc20_prize_amount, bool mintNFT)
    {
        mintNFT = false; //por default, nadie ganó nada aún
        erc20_prize_amount = 0; //acá se va ir acumulando lo que corresponda

        /*** Cálculo de los premios ***/
        uint8 matchGoalA = matches[matchId].goalA;
        uint8 matchGoalB = matches[matchId].goalB;
        uint8 betGoalA = gameData[player][matchId].goalA;
        uint8 betGoalB = gameData[player][matchId].goalB;

        MatchResult resultBet = winnerResult(betGoalA, betGoalB);
        MatchResult resultMatch = winnerResult(matchGoalA, matchGoalB);

        if (matches[matchId].typeMatch == MatchType._Group) {
            //Estamos en fase de grupos, no se chequean penales.
            if (matchGoalA == betGoalA && matchGoalB == betGoalB) {
                //Hizo un pleno: exact match, hay que mintear el NFT incluso
                erc20_prize_amount = PRIZE_GROUP_EXACT_MATCH;
                //Mintear los NFT de Seba
                mintNFT = true;
            } else {
                if (
                    resultBet == resultMatch &&
                    (matchGoalA == betGoalA || matchGoalB == betGoalB)
                ) {
                    //Acertó alguno de los marcadores y el ganador
                    erc20_prize_amount = PRIZE_GROUP_WINNER_ONE_SCORE;
                } else {
                    if (resultBet == resultMatch) {
                        //Acertó solo el ganador
                        erc20_prize_amount = PRIZE_GROUP_WINNER_NOSCORE;
                    } else {
                        if (matchGoalA == betGoalA || matchGoalB == betGoalB) {
                            //Acertó solo uno de los marcadores
                            erc20_prize_amount = PRIZE_GROUP_ONE_SCORE;
                        }
                    }
                }
            }
        } else {
            //Estamos en 8vos, 4tos, semi o final, solo se chequea quién gana y los penales
            MatchPenalty betPenaltyResult = gameData[player][matchId]
                .resultPenalty;
            MatchPenalty matchPenaltyResult = matches[matchId].resultPenalty;
            //FIXME: Hay que arreglar acá porque si acertaste gana o pierde, por más que no haya penales, te pifia el número

            if (resultBet == resultMatch) {
                //Coincidió el resultado
                erc20_prize_amount = PRIZE_MATCH_NO_PENALTIES;
                if (resultMatch == MatchResult.TIED) {
                    //Si hubo empate, ver los penales
                    if( betPenaltyResult == matchPenaltyResult){ //acertó los penales también
                        erc20_prize_amount += PRIZE_ONLY_PENALTIES;
                        mintNFT = true;
                    }
                } else { //No hubo penales, así que si acertó hay que darle el NFT
                    mintNFT = true;
                }
            }
        }
        return (erc20_prize_amount, mintNFT);
    }

    function winnerResult(uint8 goalA, uint8 goalB)
        private
        pure
        returns (MatchResult result)
    {
        if (goalA > goalB) {
            return MatchResult.A_WINS;
        }
        if (goalA < goalB) {
            return MatchResult.B_WINS;
        }
        return MatchResult.TIED;
    }

    function setTeam(
        string calldata _id,
        string calldata _name,
        uint _status
    ) public onlyRole(MATCH_ROLE) {
        teams[_id].name = _name;
        teams[_id].status = _status;
    }

    function setMatch(
        string calldata _matchId,
        uint256 _matchDate,
        string calldata _teamAID,
        string calldata _teamBID,
        MatchType _matchType
    ) public onlyRole(MATCH_ROLE) returns (Match memory match_data) {
        matches[_matchId].matchDate = _matchDate;
        matches[_matchId].status = MatchState.notplayed;
        //matches[_matchId].result = MatchResult.RESERVED;
        matches[_matchId].typeMatch = _matchType;
        matches[_matchId].teamAid = teams[_teamAID];
        matches[_matchId].teamBid = teams[_teamBID];
        return matches[_matchId];
    }

    function setMatchResult(
        string calldata _matchId,
        MatchState _matchState,
        uint8 _goalA,
        uint8 _goalB,
        MatchPenalty _resultPenalty
    ) public onlyRole(MATCH_ROLE) returns (Match memory match_data) {
        //FIXME: Agregar require de partido finalizado.
        //Debemos chequear que el Match esté en hora para apostarse.
        require(
            matches[_matchId].matchDate < block.timestamp,
            "Partido no comenzado."
        );
        matches[_matchId].status = _matchState;
        matches[_matchId].resultPenalty = _resultPenalty;
        matches[_matchId].goalA = _goalA;
        matches[_matchId].goalB = _goalB;
        return matches[_matchId];
    }

    modifier checkForPlayer() {
        require(
            IAllowlist(allowlist_contract).getUserStatus(_msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "No autorizado."
        );
        _;
    }
}
