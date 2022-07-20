const { task } = require("hardhat/config");
const Web3 = require("web3");
const transferOwnership = require("../libs/transferOwnership");

const addressType = {
  name: "address",
  parse: (argName, value) => {
    if (Web3.utils.isAddress(value)) {
      return value;
    }

    throw {
      title: "Invalid Argument",
      message: `${argName} must be a valid address`,
    };
  },
  validate(_argName, _argumentValue) {},
};

const registerTasks = () => {
  // This is a sample Hardhat task. To learn how to create your own go to
  // https://hardhat.org/guides/create-task.html
  task("accounts", "Prints the list of accounts").setAction(
    async (taskArgs, hre) => {
      const accounts = await hre.ethers.getSigners();

      for (const account of accounts) {
        console.log(account.address);
      }
    }
  );

  task(
    "transferOwnership",
    "Transfers ownership of the deployed contract instances"
  )
    .addPositionalParam(
      "newOwner",
      "The new owner's account address",
      undefined,
      addressType
    )
    .setAction(async (taskArgs, hre) => {
      await transferOwnership(taskArgs.newOwner);
    });
};

module.exports = registerTasks;
