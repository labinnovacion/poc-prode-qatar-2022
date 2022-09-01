//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------
import "../ERC20Token/IERC20Token.sol"; //Should be Cryptolink
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./DataTypesDeclaration.sol";

contract PRODE is Pausable, AccessControl {
    /***    Roles   ***/
    //El Admin 8-)
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    //Tiene permisos para pausar TODO
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    //Tiene permisos para modificar partidos
    bytes32 public constant MATCH_ROLE = keccak256("MATCH_ROLE");

    //Son los que pueden jugar
    bytes32 public constant PLAYER_ROLE = keccak256("PLAYER_ROLE");

    /***    Constantes  ***/
    address public erc20_contract = 0xbf6c50889d3a620eb42C0F188b65aDe90De958c4; //TOKEN Cryptolink2 Address
    address public erc721_contract = 0xbf6c50889d3a620eb42C0F188b65aDe90De958c4; //SebaNFT Address
    uint deadline = 1 hours;

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
    event BetCreated(
        address indexed player,
        string matchID,
        uint8 goalA,
        uint8 goalB,
        MatchPenalty penalty,
        uint betAmount
    );
    event BetCleared(address indexed player, string matchID, uint betAmount);
    event BetClaimed(address indexed player, string matchID, uint claimedPrize);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(MATCH_ROLE, _msgSender());
    }

    function setERC20Contract(address _erc20_contract)
        public
        onlyRole(ADMIN_ROLE)
    {
        emit ProdeERC20ContractSet(_erc20_contract, erc20_contract);
        erc20_contract = _erc20_contract;
    }

    function setERC721Contract(address _erc721_contract)
        public
        onlyRole(ADMIN_ROLE)
    {
        emit ProdeERC721ContractSet(_erc721_contract, erc721_contract);
        erc20_contract = _erc721_contract;
    }

    function setDeadline(uint time) public onlyRole(ADMIN_ROLE) {
        deadline = time;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /***    Funciones del PRODE    ***/
    /**
     * @dev bet/apostar: inserta en el array de apuestas una apuesta
     * @param matchId ID del partido
     * @param goalA Cantidad de goles del equipo A (Local?)
     * @param goalB Cantidad de goles del equipo B (Visitante?)
     * @param penaltyResult Resultado de los penales {0:RESERVED,1:A_WINS,2:B_WINS}
     * @param betAmount Cantidad de tokens apostados
     */
    function bet(
        string calldata matchId,
        MatchPenalty penaltyResult,
        uint8 goalA,
        uint8 goalB,
        uint betAmount
    ) public {
        //TOKEN ERC20: Verificamos que el usuario tenga suficientes tokens para apostar.
        require(
            ICryptoLink(erc20_contract).balanceOf(_msgSender()) >= betAmount,
            "El usuario no tiene suficiente saldo."
        );
        ////TOKEN ERC20: Debemos chequear que el PRODE tenga permisos para gastar estos tokens.
        require(
            ICryptoLink(erc20_contract).allowance(_msgSender(), address(this)) >=
                betAmount,
            "El PRODE no tiene permisos de gastar tus tokens."
        );
        //Debemos chequear que el Match no haya sido jugado.
        require(
            matches[matchId].status != MatchState.played,
            "El partido ya fue jugado."
        );
        //Debemos chequear que el Match esté en hora para apostarse.
        require(
            matches[matchId].matchDate >= block.timestamp + deadline,
            "El horario permitido para apostar ha terminado."
        );
        //Debemos comprobar que no haya una apuesta anterior.
        require(
            gameData[_msgSender()][matchId]._state != BetState.DEFINED,
            "Apuesta ya definida, primero limpiar apuesta."
        );
        //Debemos comprobar que no se haya claimeado.
        require(
            gameData[_msgSender()][matchId]._state != BetState.CLAIMED,
            "No se pueden realizar acciones sobre esta apuesta."
        );

        //OJO, el MATCH tiene que ser "notplayed", así evitamos apuestas en partidos jugados.
        //Si la apuesta no está definida y el partido no fue jugado, lo dejamos apostar.
        if (
            gameData[_msgSender()][matchId]._state == BetState.NOT_DEFINED &&
            matches[matchId].status == MatchState.notplayed
        ) {
            //No hay apuesta, procedemos.
            if (
                //TOKEN ERC20
                ICryptoLink(erc20_contract).transferFrom(
                    _msgSender(),
                    address(this),
                    betAmount
                )
            ) {
                //si la transferencia de tokens sale bien, ahí recién modificamos la apuesta.
                gameData[_msgSender()][matchId].goalA = goalA;
                gameData[_msgSender()][matchId].goalB = goalB;
                gameData[_msgSender()][matchId].resultPenalty = penaltyResult;
                gameData[_msgSender()][matchId].betAmount = betAmount;
                gameData[_msgSender()][matchId]._state = BetState.DEFINED;
                emit BetCreated(
                    _msgSender(),
                    matchId,
                    goalA,
                    goalB,
                    penaltyResult,
                    betAmount
                );
                return;
            } else {
                revert("Error al transferir los tokens");
            }
        }
        return;
    }

    /**
     * @dev clearBet/limpiar apuesta: elimina del array de apuestas una apuesta
     * @param matchId ID del partido
     * @return returnedBet cantidad de tokens que se devolvieron al usuario.
     */
    function clearBet(string calldata matchId)
        public
        returns (uint returnedBet)
    {
        //Debemos chequear que el Match no haya sido jugado.
        require(
            matches[matchId].status != MatchState.played,
            "El partido ya fue jugado."
        );
        //Debemos chequear que el Match esté en hora para apostarse.
        require(
            matches[matchId].matchDate >= block.timestamp - deadline,
            "El horario permitido para apostar ha terminado."
        );
        //Debemos comprobar que HAYA una apuesta anterior.
        require(
            gameData[_msgSender()][matchId]._state == BetState.DEFINED,
            "No hay apuesta que limpiar para este match."
        );
        //Debemos comprobar que no haya una apuesta anterior claimeada.
        require(
            gameData[_msgSender()][matchId]._state != BetState.CLAIMED,
            "No se pueden realizar acciones sobre esta apuesta."
        );

        //Tengo que copiar el estado actual de la apuesta por si la transferencia falla
        uint betAmount = gameData[_msgSender()][matchId].betAmount;
        uint8 goalA = gameData[_msgSender()][matchId].goalA;
        uint8 goalB = gameData[_msgSender()][matchId].goalB;
        MatchPenalty penalties = gameData[_msgSender()][matchId].resultPenalty;
        BetState betState = gameData[_msgSender()][matchId]._state;

        //OJO, el MATCH tiene que ser "notplayed", así evitamos cambiar apuestas en partidos jugados.
        //Si la apuesta está definida y el partido no fue jugado, lo dejamos limpiar.
        if (
            gameData[_msgSender()][matchId]._state == BetState.DEFINED &&
            matches[matchId].status == MatchState.notplayed
        ) {
            //Hay apuesta y el partido no fue jugado, primero lo limpiamos.
            gameData[_msgSender()][matchId].goalA = 0;
            gameData[_msgSender()][matchId].goalB = 0;
            gameData[_msgSender()][matchId].betAmount = 0;
            gameData[_msgSender()][matchId].resultPenalty = MatchPenalty
                .RESERVED;
            gameData[_msgSender()][matchId]._state = BetState.NOT_DEFINED;
            //Y luego le transferimos los tokens de vuelta al usuario.
            if (
                ICryptoLink(erc20_contract).transferFrom(
                    address(this),
                    _msgSender(),
                    betAmount
                )
            ) {
                //Si el retorno de tokens salió bien, volvemos e indicamos cuánto volvió.
                emit BetCleared(_msgSender(), matchId, betAmount);
                return betAmount;
            } else {
                //Hay apuesta y el partido no fue jugado, primero lo limpiamos.
                gameData[_msgSender()][matchId].goalA = goalA;
                gameData[_msgSender()][matchId].goalB = goalB;
                gameData[_msgSender()][matchId].betAmount = betAmount;
                gameData[_msgSender()][matchId].resultPenalty = penalties;
                gameData[_msgSender()][matchId]._state = betState;
                return 0;
            }
        }
        return 0;
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
     * @return prizeAmount Valor del premio.
     */
    function claimPrize(string calldata matchId)
        public
        returns (uint prizeAmount)
    {
        //Debemos chequear que el Match no haya sido jugado.
        require(
            matches[matchId].status == MatchState.played,
            "El partido NO ha sido jugado."
        );
        //Debemos comprobar que no se haya claimeado.
        require(
            gameData[_msgSender()][matchId]._state != BetState.CLAIMED,
            "Este premio ha sido reclamado previamente."
        );
        //Debemos comprobar que haya una apuesta anterior.
        require(
            gameData[_msgSender()][matchId]._state == BetState.DEFINED,
            "No hay apuesta definida para este partido."
        );

        /*** Cálculo de los premios ***/
        uint256 erc20_prize_amount = gameData[_msgSender()][matchId].betAmount; //acá se va ir acumulando lo que corresponda
        gameData[_msgSender()][matchId]._state = BetState.CLAIMED;
        MatchResult resultBet = winnerResult(
            gameData[_msgSender()][matchId].goalA,
            gameData[_msgSender()][matchId].goalB
        );
        MatchResult resultMatch = winnerResult(
            matches[matchId].goalA,
            matches[matchId].goalB
        );
        if (matches[matchId].typeMatch == MatchType._Group) {
            //Estamos en fase de grupos, no se chequean penales.
            if (
                matches[matchId].goalA ==
                gameData[_msgSender()][matchId].goalA &&
                matches[matchId].goalB == gameData[_msgSender()][matchId].goalB
            ) {
                //Hizo un pleno: exact match, hay que mintear el NFT incluso
                erc20_prize_amount =
                    erc20_prize_amount *
                    PRIZE_GROUP_EXACT_MATCH;
                //Mintear NFT NFT NFT NFT
            } else {
                if (
                    resultBet == resultMatch &&
                    (matches[matchId].goalA ==
                        gameData[_msgSender()][matchId].goalA ||
                        matches[matchId].goalB ==
                        gameData[_msgSender()][matchId].goalB)
                ) {
                    //Acertó alguno de los marcadores y el ganador
                    erc20_prize_amount =
                        erc20_prize_amount *
                        PRIZE_GROUP_WINNER_ONE_SCORE;
                } else {
                    if (resultBet == resultMatch) {
                        //Acertó solo el ganador
                        erc20_prize_amount =
                            erc20_prize_amount *
                            PRIZE_GROUP_WINNER_NOSCORE;
                    } else {
                        if (
                            matches[matchId].goalA ==
                            gameData[_msgSender()][matchId].goalA ||
                            matches[matchId].goalB ==
                            gameData[_msgSender()][matchId].goalB
                        ) {
                            //Acertó solo uno de los marcadores
                            erc20_prize_amount =
                                erc20_prize_amount *
                                PRIZE_GROUP_ONE_SCORE;
                        }
                    }
                }
            }
        } else {
            //Estamos en 8vos, 4tos, semi o final, solo se chequea quién gana y los penales
            if (
                resultBet == resultMatch &&
                gameData[_msgSender()][matchId].resultPenalty ==
                matches[matchId].resultPenalty
            ) {
                //Coincidió en todo, resultado y penales.
                erc20_prize_amount = erc20_prize_amount * PRIZE_MATCH_PENALTIES;
            } else {
                if (resultBet == resultMatch) {
                    //solo el resultado pero no los penales
                    erc20_prize_amount =
                        erc20_prize_amount *
                        PRIZE_MATCH_NO_PENALTIES;
                } else {
                    if (
                        gameData[_msgSender()][matchId].resultPenalty ==
                        matches[matchId].resultPenalty
                    ) {
                        //solo los penales
                        erc20_prize_amount =
                            erc20_prize_amount *
                            PRIZE_ONLY_PENALTIES;
                    }
                }
            }
        }

        //TOKEN ERC20: Si es necesario mintearle tokens al usuario...
        //Si se usara DAI u otro Token, habría que cambiar la fórmula.
        //En este caso, el prode puede mintear.
        ICryptoLink(erc20_contract).mint(_msgSender(), erc20_prize_amount);
        //Mintear los NFT de Seba
        //NFTSeba(erc721_contract).mint(_msgSender(),matchId);
        return erc20_prize_amount;
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
        MatchType _matchType,
        bool _betAllowed
    ) public onlyRole(MATCH_ROLE) returns (Match memory match_data) {
        matches[_matchId].matchDate = _matchDate;
        matches[_matchId].status = MatchState.notplayed;
        //matches[_matchId].result = MatchResult.RESERVED;
        matches[_matchId].typeMatch = _matchType;
        matches[_matchId].betAllowed = _betAllowed;
        matches[_matchId].teamAid = teams[_teamAID];
        matches[_matchId].teamBid = teams[_teamBID];
        return matches[_matchId];
    }

    function setMatchResult(
        string calldata _matchId,
        MatchState _matchState,
        uint8 _goalA,
        uint8 _goalB,
        MatchPenalty _resultPenalty,
        bool _betAllowed
    ) public onlyRole(MATCH_ROLE) returns (Match memory match_data) {
        matches[_matchId].status = _matchState;
        matches[_matchId].resultPenalty = _resultPenalty;
        matches[_matchId].betAllowed = _betAllowed;
        matches[_matchId].goalA = _goalA;
        matches[_matchId].goalB = _goalB;
        return matches[_matchId];
    }
}
