import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

async function main() {
  const socialMediaAddr = "0x8d8BeE988E144a6bF7180EB8A454a51E815C4820";

  const socialMedia = await ethers.getContractAt(
    "ISocialMedia",
    socialMediaAddr
  );

  const name = "Vic";
  const symbol = "VK";
  const role = 1;

  const uri = "ipfs/QmbLw2oDhFrivbiqWStZj9zwjHFD5ETiAazVsREUzPjJyw";
  const caption = "Cute White cat. I love this NFT";

  //   const registerUser = await socialMedia.registerUser(name, symbol, role);
  //   await registerUser.wait();

  // function createPost(string memory _uri, string memory _caption) external;

  //   const createPost = await socialMedia.createPost(uri, caption);
  //   await createPost.wait();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
