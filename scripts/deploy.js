import fs from "fs";
import ora from "ora";
import dotenv from "dotenv";
import { Wallet } from "@ethersproject/wallet";
import { hexlify, concat } from "@ethersproject/bytes";
import { JsonRpcProvider } from "@ethersproject/providers";
import { defaultAbiCoder as abi } from "@ethersproject/abi";
dotenv.config();

const Contract = JSON.parse(fs.readFileSync(
  "./out/LensHumanRaffle.sol/LensHumanRaffle.json",
  { encoding: "utf8", flag: "r" }
));

let validConfig = true;
if (process.env.RPC_URL === undefined) {
  console.log("Missing RPC_URL");
  validConfig = false;
}
if (process.env.PRIVATE_KEY === undefined) {
  console.log("Missing PRIVATE_KEY");
  validConfig = false;
}
if (!validConfig) process.exit(1);

const provider = new JsonRpcProvider(process.env.RPC_URL);
const wallet = new Wallet(process.env.PRIVATE_KEY, provider);

async function main() {
  let inputs = [
    "0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d", // lensNFT
    "0x8f9b3A2Eb1dfa6D90dEE7C6373f9C0088FeEebAB", // humanCheck
    5, // numWinners
    1665601200, // endsAt
  ];
  const spinner = ora(`Deploying your contract...`).start();

  let tx = await wallet.sendTransaction({
    data: hexlify(
      concat([
        Contract.bytecode.object,
        abi.encode(Contract.abi[0].inputs, inputs),
      ])
    ),
    gasPrice: 60000000000,
  });

  spinner.text = `Waiting for deploy transaction (tx: ${tx.hash})`;
  tx = await tx.wait();

  spinner.succeed(`Deployed your contract to ${tx.contractAddress}`);
}

main(...process.argv.splice(2)).then(() => process.exit(0));
