import { ethers } from "hardhat";

async function main() {
  const HexagonNft = await ethers.getContractFactory("HexagonNft");
  const hexagonNft = await HexagonNft.deploy();

  await hexagonNft.deployed();

  console.log("HexagonNft deployed to:", hexagonNft.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});