import { ethers } from "hardhat";

async function main() {
  const subID = 9762;
  const vrfCor = "0x8103b0a8a00be2ddc778e6e7eaa21791cd364625";
  const tokenAddr = "0x07d1ad5B9F0752527e37b065a4752aEdc28D0457";

  const airdropRewards = await ethers.deployContract(
    "AirdropRewardGame",
    [subID, vrfCor, tokenAddr],
    {}
  );

  await airdropRewards.waitForDeployment();

  console.log(`AirdropRewardGame deployed to ${airdropRewards.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
