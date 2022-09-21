const { expect } = require("chai");

const matches = require("./matches.json");
const teams = require("./teams.json");

const CRYPTOLINK_TOKENS = 10000000;
const BET_BASE = 1000;


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

    })

    describe("(ERC20) CryptoLink contract", function () {
        it("Deployment should pass.", async function () {
            const [owner] = await ethers.getSigners();
            const ownerBalance = await cryptoLinkToken.balanceOf(owner.address);
            expect(await cryptoLinkToken.totalSupply()).to.equal(ownerBalance);
        });
    });

    describe("Prode contract - Assign ERC20", function () {
        it("Deployment should assign ERC20 token and pass.", async function () {
            expect(await ProdeContract.erc20_contract()).to.equal(cryptoLinkToken.address);
        });
    });

    describe("Allowlist contract", function () {
        it("Deployment should verify address allowed or not.", async function () {
            for (const [index, val] of signers.entries()) {
                //console.log(index,val.address);
                expect(await AllowlistContract.getUserStatus(val.address)).to.equal((index === 0 || 0 < index % 5));
            };
        });
    });

    describe("Prode contract - Bet one", function () {
        it("Give tokens to users to bet... and bet.", async function () {
            for (const [idx, val] of signers.entries()) {
                //Transfer ERC20 to players to "play"
                //1: Le doy tokens
                await cryptoLinkToken.mint(val.address, CRYPTOLINK_TOKENS);

                //2: Ver si tiene saldo
                expect(await cryptoLinkToken.balanceOf(val.address)).to.equal(CRYPTOLINK_TOKENS);

                //3: Aprobar el gasto
                await cryptoLinkToken.connect(val).approve(ProdeContract.address, CRYPTOLINK_TOKENS);

                //4: Ver si tiene el Allowance
                expect(await cryptoLinkToken.connect(val).allowance(val.address, ProdeContract.address)).to.equal(CRYPTOLINK_TOKENS);

                if (idx == 0 || idx % 5) { //Es porque algunas address no están allowed
                    //5: Apostar
                    await ProdeContract.connect(val).bet2("62e9ec549bfca97afc64000b",
                        0,
                        0,
                        0,
                        idx * BET_BASE);
                    expect((await ProdeContract.gameData(val.address, "62e9ec549bfca97afc64000b")).betAmount).to.equal(idx * BET_BASE);
                }
                else { //si no están allowed, mejor buscamos el fallo.
                    await expect(ProdeContract.connect(val).bet2("62e9ec549bfca97afc64000b",
                        0,
                        0,
                        0,
                        idx * BET_BASE)).to.be.revertedWith("No autorizado.");
                }
            };
        });
    });
    describe("Prode contract - Bet, match and claim, complete.", function () {
        it("Give tokens to users, bet, update matches and claim.", async function () {

            //Primero hago todas las apuestas.
            for (const [idx, val] of signers.entries()) {
                //1: Le doy tokens
                await cryptoLinkToken.mint(val.address, CRYPTOLINK_TOKENS);

                //2: Ver si tiene saldo
                expect(await cryptoLinkToken.balanceOf(val.address)).to.equal(CRYPTOLINK_TOKENS);

                //3: Aprobar el gasto
                await cryptoLinkToken.connect(val).approve(ProdeContract.address, CRYPTOLINK_TOKENS);

                //4: Ver si tiene el Allowance
                expect(await cryptoLinkToken.connect(val).allowance(val.address, ProdeContract.address)).to.equal(CRYPTOLINK_TOKENS);

                var matchesList = await parseMatches(matches);
                //5: Apostar, pero dividir el caso de fail para las address not allowed.
                //5.a: Iterar para cada partido:
                for (const [matchIdx, matchVal] of matchesList.slice(0, 10).entries()) { //solo los primeros 10 partidos
                    let goalA = getRandomInt(5);
                    let goalB = getRandomInt(5);
                    let penalties = getRandomInt(2); //Inventa resultado, claim debería chequear que no le de bola en fase de grupos
                    if (idx == 0 || idx % 5) { //Es porque algunas address no están allowed
                        await ProdeContract.connect(val).bet2(matchVal.id,
                            penalties,
                            goalA,
                            goalB,
                            BET_BASE);
                        expect((await ProdeContract.gameData(val.address, matchVal.id)).goalA).to.equal(goalA);
                        expect((await ProdeContract.gameData(val.address, matchVal.id)).goalB).to.equal(goalB);
                        expect((await ProdeContract.gameData(val.address, matchVal.id)).resultPenalty).to.equal(penalties);

                    }
                    else { //si no están allowed, mejor buscamos el fallo.
                        await expect(ProdeContract.connect(val).bet2(matchVal.id,
                            penalties,
                            goalA,
                            goalB,
                            BET_BASE)).to.be.revertedWith("No autorizado.");
                    }
                }
            };
            //6: Actualizar matches con resultados:
            let minTimestamp = 0;
            for (const [matchIdx, matchVal] of matchesList.slice(0, 10).entries()) {
                // getting timestamp
                const blockNumBefore = await ethers.provider.getBlockNumber();
                const blockBefore = await ethers.provider.getBlock(blockNumBefore);
                const timestampBefore = blockBefore.timestamp;
                minTimestamp = (timestampBefore < matchVal.matchDate) ? matchVal.matchDate + 3600 : timestampBefore + 1;
                await network.provider.send("evm_setNextBlockTimestamp", [minTimestamp])
                await network.provider.send("evm_mine") // this one will have 2021-07-01 12:00 AM as its timestamp, no matter what the previous block has

                let goalA = getRandomInt(5);
                let goalB = getRandomInt(5);
                let penalties = getRandomInt(2); //Inventa resultado, claim debería chequear que no le de bola en fase de grupos
                //console.log(goalA, goalB, penalties, matchVal.matchDate + 3600, timestampBefore, minTimestamp)
                await ProdeContract.setMatchResult(matchVal.id, 1, goalA, goalB, penalties);
            }

            //7: Vamos a claimear, siempre que podamos!
            for (const [idx, val] of signers.entries()) {
                //7.a: Iterar para cada partido:
                for (const [matchIdx, matchVal] of matchesList.slice(0, 10).entries()) { //solo los primeros 10 partidos

                    if (idx == 0 || idx % 5) { //Es porque algunas address no están allowed
                        //let tx = await ProdeContract.connect(val).claimPrize(matchVal.id);
                        //let receipt = await tx.wait();
                        //console.log(receipt.events?.filter((x) => { return x.event == "Transfer" }));
                        await expect(ProdeContract.connect(val).claimPrize(matchVal.id)).to.emit(cryptoLinkToken,'Transfer');
                    }
                    else { //si no están allowed, mejor buscamos el fallo.
                        await expect(ProdeContract.connect(val).claimPrize(matchVal.id)).to.be.revertedWith("No autorizado.");
                    }
                }
                console.log(await cryptoLinkToken.balanceOf(val.address))
            };

            //8: Probamos claimear de vuelta:
            for (const [idx, val] of signers.entries()) {
                //7.a: Iterar para cada partido:
                for (const [matchIdx, matchVal] of matchesList.slice(0, 10).entries()) { //solo los primeros 10 partidos

                    if (idx == 0 || idx % 5) { //Es porque algunas address no están allowed
                        await expect(ProdeContract.connect(val).claimPrize(matchVal.id)).to.be.revertedWith('Apuesta ya reclamada.');
                    }
                    else { //si no están allowed, mejor buscamos el fallo.
                        await expect(ProdeContract.connect(val).claimPrize(matchVal.id)).to.be.revertedWith("No autorizado.");
                    }
                }
            };
        });
    });


    describe("Prode contract - Bet one, match and claim, winner.", function () {
        it("Give tokens to one user, bet one, update match and claim winning.", async function () {

            //Primero hago todas las apuestas.
            for (const [idx, val] of signers.entries()) {
                //1: Le doy tokens
                await cryptoLinkToken.mint(val.address, CRYPTOLINK_TOKENS);

                //2: Ver si tiene saldo
                expect(await cryptoLinkToken.balanceOf(val.address)).to.equal(CRYPTOLINK_TOKENS);

                //3: Aprobar el gasto
                await cryptoLinkToken.connect(val).approve(ProdeContract.address, CRYPTOLINK_TOKENS);

                //4: Ver si tiene el Allowance
                expect(await cryptoLinkToken.connect(val).allowance(val.address, ProdeContract.address)).to.equal(CRYPTOLINK_TOKENS);

                var matchesList = await parseMatches(matches);
                //5: Apostar, pero dividir el caso de fail para las address not allowed.
                //5.a: Iterar para cada partido:
                for (const [matchIdx, matchVal] of matchesList.slice(0, 10).entries()) { //solo los primeros 10 partidos
                    let goalA = getRandomInt(5);
                    let goalB = getRandomInt(5);
                    let penalties = getRandomInt(2); //Inventa resultado, claim debería chequear que no le de bola en fase de grupos
                    if (idx == 0 || idx % 5) { //Es porque algunas address no están allowed
                        await ProdeContract.connect(val).bet2(matchVal.id,
                            penalties,
                            goalA,
                            goalB,
                            BET_BASE);
                        expect((await ProdeContract.gameData(val.address, matchVal.id)).goalA).to.equal(goalA);
                        expect((await ProdeContract.gameData(val.address, matchVal.id)).goalB).to.equal(goalB);
                        expect((await ProdeContract.gameData(val.address, matchVal.id)).resultPenalty).to.equal(penalties);

                    }
                    else { //si no están allowed, mejor buscamos el fallo.
                        await expect(ProdeContract.connect(val).bet2(matchVal.id,
                            penalties,
                            goalA,
                            goalB,
                            BET_BASE)).to.be.revertedWith("No autorizado.");
                    }
                }
            };
            //6: Actualizar matches con resultados:
            let minTimestamp = 0;
            for (const [matchIdx, matchVal] of matchesList.slice(0, 10).entries()) {
                // getting timestamp
                const blockNumBefore = await ethers.provider.getBlockNumber();
                const blockBefore = await ethers.provider.getBlock(blockNumBefore);
                const timestampBefore = blockBefore.timestamp;
                minTimestamp = (timestampBefore < matchVal.matchDate) ? matchVal.matchDate + 3600 : timestampBefore + 1;
                await network.provider.send("evm_setNextBlockTimestamp", [minTimestamp])
                await network.provider.send("evm_mine") // this one will have 2021-07-01 12:00 AM as its timestamp, no matter what the previous block has

                let goalA = getRandomInt(5);
                let goalB = getRandomInt(5);
                let penalties = getRandomInt(2); //Inventa resultado, claim debería chequear que no le de bola en fase de grupos
                //console.log(goalA, goalB, penalties, matchVal.matchDate + 3600, timestampBefore, minTimestamp)
                await ProdeContract.setMatchResult(matchVal.id, 1, goalA, goalB, penalties);
            }

            //7: Vamos a claimear, siempre que podamos!
            for (const [idx, val] of signers.entries()) {
                //7.a: Iterar para cada partido:
                for (const [matchIdx, matchVal] of matchesList.slice(0, 10).entries()) { //solo los primeros 10 partidos

                    if (idx == 0 || idx % 5) { //Es porque algunas address no están allowed
                        //let tx = await ProdeContract.connect(val).claimPrize(matchVal.id);
                        //let receipt = await tx.wait();
                        //console.log(receipt.events?.filter((x) => { return x.event == "Transfer" }));
                        await expect(ProdeContract.connect(val).claimPrize(matchVal.id)).to.emit(cryptoLinkToken,'Transfer');
                    }
                    else { //si no están allowed, mejor buscamos el fallo.
                        await expect(ProdeContract.connect(val).claimPrize(matchVal.id)).to.be.revertedWith("No autorizado.");
                    }
                }
                console.log(await cryptoLinkToken.balanceOf(val.address))
            };

            //8: Probamos claimear de vuelta:
            for (const [idx, val] of signers.entries()) {
                //7.a: Iterar para cada partido:
                for (const [matchIdx, matchVal] of matchesList.slice(0, 10).entries()) { //solo los primeros 10 partidos

                    if (idx == 0 || idx % 5) { //Es porque algunas address no están allowed
                        await expect(ProdeContract.connect(val).claimPrize(matchVal.id)).to.be.revertedWith('Apuesta ya reclamada.');
                    }
                    else { //si no están allowed, mejor buscamos el fallo.
                        await expect(ProdeContract.connect(val).claimPrize(matchVal.id)).to.be.revertedWith("No autorizado.");
                    }
                }
            };
        });
    });
})