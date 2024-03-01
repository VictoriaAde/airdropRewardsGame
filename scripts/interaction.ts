import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

async function main() {
  const tokenAddr = "0x07d1ad5B9F0752527e37b065a4752aEdc28D0457";
  const airdropRewardsAddr = "0xcEc8854F6D87B1a100a36F46C835D4607F685dA1";

  const airdropRewards = await ethers.getContractAt(
    "IRewardToken",
    airdropRewardsAddr
  );

  const tokenContract = await ethers.getContractAt("IERC20", tokenAddr);

  const register = await airdropRewards.registerParticipant();
  await register.wait();

  // const requestWords = await airdropRewards.requestRandomWords();
  // await requestWords.wait();

  // console.log(requestWords);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
