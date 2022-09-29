//script/deploy.js
//How to: npx hardhat run scripts/Auction.deploy.js --network <network-name>

const matches = require("../test/matches.json");
const teams = require("../test/teams.json");


//FIXME: Avisar a Flika que los define no son exactamente iguales.

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

function getRandomInt(max) {
    return Math.floor(Math.random() * max);
}

async function parseMatches(matchesArray) {
    var retVal = []
    matchesArray.forEach((val, idx) => {
        retVal.push({
            id: val['_id']['$oid'],
            matchDate: Math.round(parseInt(val['matchDate']['$date']['$numberLong']) / 1000),
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

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    // CryptoLink2: Deployar CRL2
    const CryptoLink = await ethers.getContractFactory("CryptoLink");
    cryptoLinkToken = await CryptoLink.deploy();
    console.log("CryptoLink Token address:", cryptoLinkToken.address);

    // Allowlist: Deployar
    const Allowlist = await ethers.getContractFactory("Allowlist");
    AllowlistContract = await Allowlist.deploy();
    console.log("AllowList address:", AllowlistContract.address);

    // Allowlist: Populate
    //await AllowlistContract.setUserStatus(val.address, true); //Add the owner to the allowed  

    // Prode: Deploy
    const Prode = await ethers.getContractFactory("Prode");
    ProdeContract = await Prode.deploy();
    console.log("Prode address:", ProdeContract.address);


    //Asignar el TOKEN ERC20 al Prode
    await ProdeContract.setERC20Contract(cryptoLinkToken.address);
    //Asignar al PRODE como minter en el ERC20:
    await cryptoLinkToken.grantRole(cryptoLinkToken.MINTER_ROLE(), ProdeContract.address);


    //Asignar el Allowlist al Prode y al ERC20
    await ProdeContract.setAllowlistContract(AllowlistContract.address);
    await cryptoLinkToken.setAllowlistContract(AllowlistContract.address);

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
  }

 
 main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });