const { ethers, upgrades } = require("hardhat")

/**  * 2025/02/15 in sepolia testnet
 * esVault contract deployed to: 0xaD65f3dEac0Fa9Af4eeDC96E95574AEaba6A2834
     esVault ImplementationAddress: 0x5D034EA7F15429Bcb9dFCBE08Ee493F001063AF0
     esVault AdminAddress: 0xe839419C14188F7b79a0E4C09cFaF612398e7795
   esDex contract deployed to: 0xcEE5AA84032D4a53a0F9d2c33F36701c3eAD5895
      esDex ImplementationAddress: 0x17B2d83BFE9089cd1D676dE8aebaDCA561f55c96
      esDex AdminAddress: 0xe839419C14188F7b79a0E4C09cFaF612398e7795
 */

/**  * 2025/09/24 in sepolia testnet
esVault contract deployed to: 0x6cA1dade166322e1AEC272e7fB180d9Fc4847117
0xCC980d87263f7bE2cD847582B14625d163d038F4  esVault getImplementationAddress
0x6030fbcc5a06c4765B46f946C8ca9521153a7190  esVault getAdminAddress5

esDex contract deployed to: 0x12F86EF70E2c0e4d04fd13db35C396eC2331aC7A
0xcA0c903427829fD4F5Ac548dBBEc92b70E19892B  esDex getImplementationAddress
0x6030fbcc5a06c4765B46f946C8ca9521153a7190  esDex getAdminAddress

deployer:  0x74B5057e77D4F58CcC70bF1c7dc9f8405BCc72f0
esVault setOrderBook tx: 0x6c2274767ce524d6ef400d63815ad05135e53501accbcaf19183a07a10739144
*/

async function main() {
  const [deployer] = await ethers.getSigners()
  console.log("deployer: ", deployer.address)

  // let esVault = await ethers.getContractFactory("EasySwapVault")
  // esVault = await upgrades.deployProxy(esVault, { initializer: 'initialize' });
  // await esVault.deployed()
  // console.log("esVault contract deployed to:", esVault.address)
  // console.log(await upgrades.erc1967.getImplementationAddress(esVault.address), " esVault getImplementationAddress")
  // console.log(await upgrades.erc1967.getAdminAddress(esVault.address), " esVault getAdminAddress")

  // newProtocolShare = 200;
  // newESVault = "0xaD65f3dEac0Fa9Af4eeDC96E95574AEaba6A2834";
  // EIP712Name = "EasySwapOrderBook";
  // EIP712Version = "1";
  // let esDex = await ethers.getContractFactory("EasySwapOrderBook")
  // esDex = await upgrades.deployProxy(esDex, [newProtocolShare, newESVault, EIP712Name, EIP712Version], { initializer: 'initialize' });
  // await esDex.deployed()
  // console.log("esDex contract deployed to:", esDex.address)
  // console.log(await upgrades.erc1967.getImplementationAddress(esDex.address), " esDex getImplementationAddress")
  // console.log(await upgrades.erc1967.getAdminAddress(esDex.address), " esDex getAdminAddress")


  // esDexAddress = "0xcEE5AA84032D4a53a0F9d2c33F36701c3eAD5895"
  // esVaultAddress = "0xaD65f3dEac0Fa9Af4eeDC96E95574AEaba6A2834"
  esDexAddress = "0x12F86EF70E2c0e4d04fd13db35C396eC2331aC7A"
  esVaultAddress = "0x6cA1dade166322e1AEC272e7fB180d9Fc4847117"
  const esVault = await (
    await ethers.getContractFactory("EasySwapVault")
  ).attach(esVaultAddress)
  tx = await esVault.setOrderBook(esDexAddress)
  await tx.wait()
  console.log("esVault setOrderBook tx:", tx.hash)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
