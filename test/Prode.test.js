const { expect } = require("chai");

const matches = require("./matches.json");
const teams = require("./teams.json");

const CRYPTOLINK_TOKENS = 10000000;
const BET_BASE = 1000;


const typeMatchConversion = {
    "Group": () => 0,
    "8VO": () => 1,
    "4TO": () => 2,
    "Semifinal": () => 3,
    "Final": () => 4
};

async function parseTeams(teamsArray) {
    var retVal = []
    teamsArray.forEach((val, idx) => {
        retVal.push({
            id: val['_id']['$oid'],
            name: val['name']
        })
    }
    )
    return retVal;
}

async function parseMatches(matchesArray) {
    var retVal = []
    matchesArray.forEach((val, idx) => {
        retVal.push({
            id: val['_id']['$oid'],
            matchDate: val['matchDate']['$date']['$numberLong'],
            status: (val.status == 'notplayed') ? 0 : 1,
            teamAid: (val.teamA) ? val.teamA['$oid'] : "",
            teamBid: (val.teamB) ? val.teamB['$oid'] : "",
            goalA: val.goalA,
            goalB: val.goalB,
            typeMatch: typeMatchConversion[val.typeMatch](),
            resultPenalty: val.resultPenalty
        })
    }
    )
    return retVal;
}

describe("PRODE QATAR 2022", () => {

    let cryptoLinkToken, AllowlistContract, ProdeContract;
    let signers;

    beforeEach(async () => {
        // CryptoLink2: Deployar CRL2
        signers = await ethers.getSigners();
        const CryptoLink = await ethers.getContractFactory("CryptoLink");
        cryptoLinkToken = await CryptoLink.deploy();

        // Allowlist: Deployar
        const Allowlist = await ethers.getContractFactory("Allowlist");
        AllowlistContract = await Allowlist.deploy();
        // Allowlist: Populate

        signers.forEach(async (val, index) => {
            if (index == 0 || index % 5) { //Las address múltiplo de 5 las pongo como "blacklist"
                await AllowlistContract.setUserStatus(val.address, true); //Add the owner to the allowed  
            }
        });

        // Prode: Deploy
        const Prode = await ethers.getContractFactory("Prode");
        ProdeContract = await Prode.deploy();

        //Asignar el TOKEN ERC20 al Prode
        await ProdeContract.setERC20Contract(cryptoLinkToken.address);

        //Cargar Teams del json:
        (await parseTeams(teams)).forEach(async (element, idx) => {
            await ProdeContract.setTeam(element.id, element.name, 0);
        });

        //Cargar matches del json:
        (await parseMatches(matches)).forEach(async (element, idx) => {
            await ProdeContract.setMatch(
                element.id,
                element.matchDate,
                element.teamAid,
                element.teamBid,
                element.typeMatch
            );
        });

    })

    describe("(ERC20) CryptoLink contract", function () {
        it("Deployment should pass.", async function () {
            const [owner] = await ethers.getSigners();
            const ownerBalance = await cryptoLinkToken.balanceOf(owner.address);
            expect(await cryptoLinkToken.totalSupply()).to.equal(ownerBalance);
        });
    });

    describe("Prode contract", function () {
        it("Deployment should assign ERC20 token and pass.", async function () {
            expect(await ProdeContract.erc20_contract()).to.equal(cryptoLinkToken.address);
        });
    });

    describe("Allowlist contract", function () {
        it("Deployment should verify address allowed or not.", async function () {
            for( const [index,val] of signers.entries() ) {
                //console.log(index,val.address);
                expect(await AllowlistContract.getUserStatus(val.address)).to.equal((index === 0 || 0< index%5));
            };
        });
    });

    describe("Prode contract", function () {
        it("Give tokens to users to bet... and bet.", async function () {
            //console.log(await ProdeContract.teams("62d73d39baf01be1797e26bf"));
            //console.log(await ProdeContract.matches("62e9ec549bfca97afc64000e"))

            //Transfer ERC20 to players to "play"
            for (const [idx,val] of signers.entries()){
                //1: Le doy tokens
                await cryptoLinkToken.mint(val.address, CRYPTOLINK_TOKENS);

                //2: Ver si tiene saldo
                expect(await cryptoLinkToken.balanceOf(val.address)).to.equal(CRYPTOLINK_TOKENS);

                //3: Aprobar el gasto
                await cryptoLinkToken.connect(val).approve(ProdeContract.address, CRYPTOLINK_TOKENS);

                //4: Ver si tiene el Allowance
                expect(await cryptoLinkToken.connect(val).allowance(val.address, ProdeContract.address)).to.equal(CRYPTOLINK_TOKENS);

                await ProdeContract.connect(val).bet2("62e9ec549bfca97afc64000b",
                0,
                0,
                0,
                idx*BET_BASE);
                expect((await ProdeContract.gameData(val.address, "62e9ec549bfca97afc64000b")).betAmount).to.equal(idx*BET_BASE);
            };
        });
    });
})