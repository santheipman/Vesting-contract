const { ethers } = require('hardhat');
const { expect } = require('chai');
const { inputToConfig } = require('@ethereum-waffle/compiler');

describe("Vesting", function () {
    let owner;
    let invester;

    let token;
    let vesting;

    let startTime;
    let totalPeriod;
    let timePerPeriod;
    let cliff;
    let totalTokens;

    beforeEach(async function () {
        const provider = await ethers.provider; // Hardhat Network (local)

        const beginTime = (await provider.getBlock("latest")).timestamp;

        const firstRelease = 20; // "fistReleaseRatio = 20" means 20% of max amount of claimable tokens will be released first
        timeDurationBeforeStart = 6;
        startTime = beginTime + timeDurationBeforeStart;
        totalPeriod = 4;
        timePerPeriod = 6;
        cliff = 6;
        totalTokens = 20_000;
        
        [owner, invester] = await ethers.getSigners();
        const tokenContract = await ethers.getContractFactory("TestToken");
        const vestingContract = await ethers.getContractFactory("Vesting");

        token = await tokenContract.deploy(totalTokens);
        vesting = await vestingContract.deploy(
            token.address,
            firstRelease,
            startTime,
            totalPeriod,
            timePerPeriod,
            cliff,
            totalTokens,
            owner.address
        );
    });

    describe("Token contract", function () {
        it("Should mint correct amount of tokens and send to contract's owner", async function() {
            expect(await token.balanceOf(owner.address)).to.equal(totalTokens);
        });
    });

    describe("Vesting contract", function () {

        it("Should allow owner to send tokens to vesting contract in order to lock the tokens", async function () {
            await token.transfer(vesting.address, totalTokens);
            expect(await token.balanceOf(vesting.address)).to.equal(totalTokens);
        });

        it("Should allow owner to add users to the whitelist", async function () {
            await vesting.addUserToWhitelist(invester.address, 12000);
            expect(await vesting.getUserAmount(invester.address)).to.equal(12000);
        });

        it("Should allow owner to remove users from the whitelist", async function () {
            await vesting.addUserToWhitelist(invester.address, 12000);
            await vesting.removeUserFromWhitelist(invester.address);
            expect(await vesting.getUserAmount(invester.address)).to.equal(0);
        });

        describe("Should vest correctly", function () {

            beforeEach(async function () {
                // fundrasing
                await token.transfer(vesting.address, totalTokens);
    
                // add investor
                vesting.addUserToWhitelist(invester.address, 12000);
            });

            describe("Claim one-time-only", function () {
                it("Before startTime", async function() {
                    await vesting.connect(invester).claimToken();
                    expect(await token.balanceOf(invester.address)).to.equal(0);
                });

                it("During cliff", async function() {
                    await new Promise(resolve => setTimeout(resolve, (timeDurationBeforeStart + 1) * 1000));
                    await vesting.connect(invester).claimToken();
                    expect(await token.balanceOf(invester.address)).to.equal(2400);
                });

                it("During 2nd period", async function() {
                    await new Promise(resolve => setTimeout(resolve, (timeDurationBeforeStart + cliff + timePerPeriod + 1) * 1000));
                    await vesting.connect(invester).claimToken();
                    expect(await token.balanceOf(invester.address)).to.equal(7200);
                });

                it("After the last release", async function() {
                    await new Promise(resolve => setTimeout(resolve, (timeDurationBeforeStart + cliff + timePerPeriod * totalPeriod + 1) * 1000));
                    await vesting.connect(invester).claimToken();
                    expect(await token.balanceOf(invester.address)).to.equal(12000);
                });
            });

            it("Claim more than one time", async function () {
                await new Promise(resolve => setTimeout(resolve, (timeDurationBeforeStart + 1) * 1000));
                await vesting.connect(invester).claimToken();
                expect(await token.balanceOf(invester.address)).to.equal(2400);

                await new Promise(resolve => setTimeout(resolve, ((timeDurationBeforeStart + cliff + timePerPeriod * 2 + 1) - (timeDurationBeforeStart + 1)) * 1000));
                await vesting.connect(invester).claimToken();
                expect(await token.balanceOf(invester.address)).to.equal(9600);
            });
        });
    });
})